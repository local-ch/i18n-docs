module I18nDocs

  class CsvToYaml

    attr_reader :input_file, :output_file, :locales, :translations, :aliases

    def self.root_path
      @root_path ||= defined?(Rails) ? Rails.root : Pathname.new(Dir.pwd)
    end

    def initialize(input_file, output_file, locales = [])
      @input_file = input_file
      @output_file = File.basename(output_file)
      @locales = locales.map(&:to_s)

      # init translation hash
      @translations = {}
      @aliases = {}
      @locales.each do |locale|
        @translations[locale] = {}
        @aliases[locale] = {}
      end
    end


    def write_files
      @locales.each do |locale|
        output_file_path = self.class.root_path.join('config', 'locales', locale, @output_file)
        FileUtils.mkdir_p File.dirname(output_file_path)

        File.open(output_file_path, 'w') do |file|
          hashes = []
          alias_hash(@aliases[locale], hashes)
          final_hash = {locale => @translations[locale]}
          file.puts remove_alias_quotes(alias_only_corrected(YAML::dump(final_hash), hashes))
        end
        puts "File '#{@output_file}' for language '#{locale}' written to disc (#{output_file_path})"
      end
    end


    def process
      CSV.foreach(@input_file, headers: true) do |row|
        process_row(row.to_hash)
      end
    end

    def process_row(row_hash)
      key = row_hash.delete('key')
      return unless key

      key_elements = key.split('.')
      @locales.each do |locale|
        raise "Locale missing for key #{key}! (locales in app: #{@locales} / locales in file: #{row_hash.keys.to_s})" if !row_hash.has_key?(locale)
        unless alias_only? row_hash[locale]
          store_translation(key_elements, locale, row_hash[locale], @translations)
        else
          store_translation(key_elements, locale, row_hash[locale], @aliases)
        end
      end
    end

    def store_translation(keys, locale, value, hash_store)
      return nil if value.nil?    # we don't store keys that don't have a valid value
      # Google Spreadsheet does not export empty strings and therefore we use '_' as a replacement char.
      value = '' if value == '_'

      keys.each(&:strip!)
      tree = keys[0...-1]
      leaf = keys.last
      data_hash = tree.inject(hash_store[locale]) do |memo, k|
        if memo.is_a? Hash
          if memo.has_key?(k)
              memo[k]
          else
            memo[k] = {}
          end
        else
          raise "Error around key '#{keys.join '.'}': Expected #{memo.inspect} to be a Hash"
        end
      end

      if data_hash.is_a? String
        raise "Error around key '#{keys.join '.'}': Expected #{data_hash.inspect} to be a Hash"
      end

      data_hash[leaf] = value
    end

    private
      # Must handle aliases with/without a value differently addressable: &addressable vs name: &name Name
      def alias_only?(key)
        true if key && key[0] == '&' && key.split.size == 1
      end

      # leaf hash having an alias as its value
      def alias_hash(hash, result)
        hash.each do |k,v|
          if v.kind_of? Hash
            alias_hash v, result
          else
            if alias_only?(v)
              result << {k => v}
            end
          end
        end
        result
      end

      def alias_only_corrected(yaml_string, alias_only_hashes)
        alias_only_hashes.each do |hash|
          hash.each do |k,v|
            yaml_string.gsub! "#{k}:\n", "#{k}: #{v}\n"
          end
        end
        yaml_string
      end

      # an alias is quoted by default,
      # convert blah: "&alias content" to convert blah: &alias content
      def remove_alias_quotes(yaml_string)
        yaml_string.scan(/: \"[\&,\*].*\"$/).each do |alias_quoted|
          yaml_string.gsub!(alias_quoted, alias_quoted.gsub(/: \"/,": ").gsub(/\"$/,""))
        end
        yaml_string.scan(/: \'[\&,\*].*\'$/).each do |alias_quoted|
          yaml_string.gsub!(alias_quoted, alias_quoted.gsub(/: \'/,": ").gsub(/\'$/,""))
        end
        yaml_string
      end

  end

end
