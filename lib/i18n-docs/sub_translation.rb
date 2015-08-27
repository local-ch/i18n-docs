module I18nDocs

  Status = Struct.new(:downloaded, :imported, :exported, :uploaded)

  class SubTranslation

    attr_accessor :nested_translations, :flat_translations

    attr_accessor :yml, :csv, :tmp_file, :url, :existing_locales, :manager, :status

    attr_accessor :google_drive_key, :google_drive_worksheet

    def initialize(yml_file,url,existing_locales,manager)
      # Make sure targets are yml files
      yml_file = yml_file + ".yml" if yml_file !~ /\.yml$/

      self.yml = yml_file
      self.url = url
      self.existing_locales = existing_locales

      self.manager = manager

      self.nested_translations = {}
      self.flat_translations = {}

      manager.locales.each do |locale|
        self.nested_translations[locale] = {}
        self.flat_translations[locale] = {}
      end

      # Create CSV pendant file
      self.csv = File.basename(yml).gsub('.yml', '.csv')
      # Temporary transit file
      self.tmp_file = File.join(manager.tmp_dir, csv)
      # Nothing done yet
      self.status = Status.new(false,false,false,false)
      # Google Drive
      set_google_drive_info
    end

    def to_s
      "#{yml} - #{get_status.map(&:to_s).join('-')}"
    end

    def download
      puts "    #{csv}: downloaded from #{url} to #{tmp_file}"

      if is_google_drive?
        if manager.google_drive_manager.download(google_drive_key, google_drive_worksheet, tmp_file)
          self.status.downloaded = true
        else
          self.status.downloaded = false
        end
      else
        doc_data = open(url).read.force_encoding('UTF-8')
        File.open(tmp_file, 'w') do |dst|
          dst.write(doc_data)
        end
        self.status.downloaded = true
      end
    end

    def import()
      puts "    From #{csv}"
      load_csv
      force_fallback if manager.options['force_fallback']
      nest_translations
      export_to_yml
      self.status.imported = true
    end

    def export()
      load_locales
      flatten_translations
      export_to_csv
      self.status.exported = true
    end

    def upload
      if is_google_drive?
        manager.google_drive_manager.upload(tmp_file, google_drive_key, google_drive_worksheet)
        self.status.uploaded = true
      else
        FileUtils.cp(tmp_file,url)
      end
    end

    def clean_up
      puts "    #{csv} deleted"
      File.unlink(tmp_file)
    end

    def is_google_drive?
      Utils.present?(google_drive_key) && Utils.present?(google_drive_worksheet)
    end

    private

    # generic

    def get_status
      s = []
      s << 'downloaded' if status.downloaded
      s << 'imported'   if status.imported
      s << 'exported'   if status.exported
      s << 'uploaded'   if status.uploaded
      s
    end

    def set_google_drive_info
      google_drive = /^google-drive\|(.*)\|(.*)/

      if result = url.match(google_drive)
        self.google_drive_key       = result[1]
        self.google_drive_worksheet = result[2]
      else
        self.google_drive_key = nil
      end
    end

    ##########
    # IMPORT #
    ##########

    def load_csv
      CSV.foreach(tmp_file, headers: true) do |row|
        row_hash = row.to_hash

        key = row_hash.delete('key')

        manager.locales.each do |locale|
          raise "Locale missing for key #{key}! (locales in app: #{manager.locales} / locales in file: #{row_hash.keys.to_s})" unless row_hash.has_key?(locale)
          self.flat_translations[locale][key] = row_hash[locale]
        end
      end
    end

    def default_flat_translations
      flat_translations[manager.default_locale]
    end

    def force_fallback
      flat_translations.each do |locale,translations|
        translations.each do |composed_key,translation|
          if Utils.present?(composed_key) && Utils.blank?(translation)
            if Utils.blank?(default_flat_translations[composed_key])
              translations[composed_key] = Utils.humanize(composed_key.split('.').last)
            else
              translations[composed_key] = default_flat_translations[composed_key]
            end
          end
        end
      end
    end

    def nest_translations
      flat_translations.each do |locale,translations|
        translations.each do |composed_key,translation|
          nest_translation(locale, composed_key, translation)
        end
      end
    end

    def nest_translation(locale, composed_key , value)
      # we don't store keys that don't have a valid value
      if value.nil?
        nil
      else
        keys = composed_key.split('.')
        keys.each(&:strip!)
        tree = keys[0...-1]
        leaf = keys.last
        data_hash = tree.inject(nested_translations[locale]) do |memo, k|
          if memo.has_key?(k)
            memo[k]
          else
            memo[k] = {}
          end
        end
        data_hash[leaf] = decode(value)
      end
    end

    def export_to_yml
      # Write each sub_translation in each locale
      nested_translations.each do |locale,translations|
        output_file_path = locale_file(locale)

        content = if Utils.present?(translations)
          translations
        else
          {'i18n-docs' => 'default content generated by i18n-docs'}
        end

        if manager.options['include_locale_key']
          content = {locale => content}
        end

        # YML
        File.open(output_file_path, 'w') do |file|
          file.puts YAML::dump(content)
        end
        puts "      #{output_file_path} written on disk for locale '#{locale}'"
      end
    end

    ##########
    # EXPORT #
    ##########

    def load_locales
      manager.locales.each do |locale|
        self.nested_translations[locale] = load_locale(locale)
      end
    end

    def load_locale(locale)
      puts "      #{yml}: load translations for '#{locale}'"
      input_file = locale_file(locale)

      if File.file?(input_file)
        content = YAML.load_file(input_file)
        content = content[locale] if manager.options['include_locale_key']
      else
        raise "#{input_file} not found"
      end

      content
    end

    def flatten_translations
      nested_translations.each do |locale,nested_translation|
        self.flat_translations[locale] = flatten_hash(nested_translation)
      end
    end

    def flatten_hash(hash, parent_key = [])
      flat_hash = {}

      hash.each do |key, t|
        current_key = parent_key.dup << key
        if t.is_a?(Hash)
          # descend
          flat_hash.merge!(flatten_hash(t, current_key))
        else
          # leaf -> store as value for key
          flat_hash[current_key.join('.')] = t
        end
      end
      flat_hash
    end

    def export_to_csv
      puts "    #{yml} write CSV to '#{tmp_file}' \n\n"

      CSV.open(tmp_file, "wb") do |csv|
        csv << (["key"] + manager.locales)

        flat_translations[manager.default_locale].keys.sort.each do |key|
          values = manager.locales.map do |locale|
            encode(flat_translations[locale][key])
          end
          csv << values.unshift(key)
        end
      end
    end

    #########
    # UTILS #
    #########

    def locale_file(locale)
      if manager.options['single_locale_file']
         File.join(manager.locales_dir, "#{locale}.yml")
      else
        File.join(manager.locales_dir, locale, yml)
      end
    end

    ###################
    # ENCODE / DECODE #
    ###################

    def encode(value)
      # To force:
      # empty string, use "-"
      # one whitespace, use "--"
      value = "_" if value == ""
      value = "__" if value == " "
      value
    end

    def decode(value)
      begin
        new_value = YAML.load(value)
      rescue Psych::SyntaxError => e
        # Special cases
        array_regex = /^\[(.*)\]$/

        if value =~ array_regex
          symbol_array_regex = /:(\w*),?/
          result = value.scan(symbol_array_regex)
          if Utils.present?(result)
            new_value = result.flatten.map(&:to_sym)
          end
        end

        new_value ||= value
      end

      # To force:
      # empty string, use "-"
      # one whitespace, use "--"
      new_value = "" if new_value == "_"
      new_value = " " if new_value == "__"

      new_value
    end
  end
end
