module I18nDocs
  class TranslationsManager

    attr_accessor :config, :use_rails, :use_i18n, :ruby_options, :options, :locales, :default_locale, :locales_dir, :tmp_dir, :google_drive_manager, :sub_translations

    # Class methods

    def self.import_translations(ruby_options = {})
      translations_manager = I18nDocs::TranslationsManager.new(ruby_options)
      translations_manager.download_files
      translations_manager.import_translations
      translations_manager.clean_up
    end

    def self.export_translations(ruby_options = {})
      translations_manager = I18nDocs::TranslationsManager.new(ruby_options)
      translations_manager.export_translations
      translations_manager.upload_files
      translations_manager.clean_up
    end

    # Instance methods

    def initialize(ruby_options = {})
      check_rails()

      set_ruby_options(ruby_options)

      set_config()
      set_options()

      set_locales()
      set_default_locale()
      set_directories()

      set_sub_translations()

      if use_google_drive?
        set_google_drive_manager()
      end

      print_introduction()
    end

    def print_introduction
      puts ""
      puts "  Detected locales: #{locales}"
      puts "  Main locale: \"#{default_locale}\""

      puts "  Using rails: #{use_rails}"
      puts "  Using I18n: #{use_i18n}"
      puts "  Using GoogleDrive: #{use_google_drive?}"

      if options['single_locale_file']
        puts "  Looking for translations in: #{locales_dir}/"
      else
        puts "  Declared files:"
        sub_translations.each {|sb| puts "    * #{sb.yml}: avalaible in #{sb.existing_locales}" }
      end
      puts ""
    end

    def print_summary
      puts "Summary"
    end

    # Import

    def download_files
      puts "  Start downloading files:"
      sub_translations.each do |sub_translation|
        sub_translation.download
      end
    end

    def import_translations
      puts "  Start importing translations:"
      sub_translations.each do |sub_translation|
        sub_translation.import
      end
    end

    # Export

    def export_translations
      puts "  Start exporting translations:"
      sub_translations.each do |sub_translation|
        sub_translation.export
      end
    end

    def upload_files
      puts "  Start uploading files:"
      sub_translations.each do |sub_translation|
        sub_translation.upload
      end
    end

    def clean_up
      # remove all tmp files
      unless options['cleanup'] == false
        puts "  Start cleaning files:"
        sub_translations.each do |sub_translation|
          sub_translation.clean_up
        end
      end
    end

    private

    def check_rails
      self.use_rails = !defined?(Rails).nil?
      self.use_i18n = !defined?(I18n).nil? && use_rails
    end

    def set_ruby_options(ruby_options)
      self.ruby_options = ruby_options
    end

    def set_config
      # Get configuration file
      # Fallback
      # 1. ruby / 2. ENV / 3. same level / 4. rails
      if ruby_options['i18n-docs-path'] && load_config_file(File.join(ruby_options['i18n-docs-path'],'i18n-docs.yml'))
        true
      elsif ENV['i18n-docs-path'] && load_config_file(File.join(ENV['i18n-docs-path'],'i18n-docs.yml'))
        true
      elsif load_config_file(File.join(Dir.pwd,'i18n-docs.yml'))
        true
      elsif use_rails
        load_config_file(Rails.root.join('config', 'i18n-docs.yml'))
        true
      else
        raise "No config file 'i18n-docs.yml' found."
      end
    end

    def load_config_file(config_file)
      if !config_file.nil? && File.file?(config_file)
        begin
          self.config = YAML.load_file(config_file) || {}
          self.config['options'] ||= {}
          true
        rescue Psych::SyntaxError => e
          puts "YAML parsing error"
          puts "#{e.message}"
          false
        end
      else
        false
      end
    end

    def set_options(ruby_options = {})
      files = option_fallback('files')

      self.options = {
        'default_locale'      => option_fallback('default_locale'),
        'locales'             => option_fallback('locales'),
        'files'               => files,
        'files_only'          => option_fallback('files_only'),
        'cleanup'             => option_fallback('cleanup',true),
        'debugger'            => option_fallback('debugger',0),

        'tmp_dir'             => option_fallback('tmp_dir'),
        'locales_dir'         => option_fallback('locales_dir'),
        'single_locale_file'  => ([true,"true"].include? option_fallback('single_locale_file') && files.count == 1),
        'include_locale_key'  => option_fallback('include_locale_key',true),
        'force_fallback'      => option_fallback('force_fallback',false)
      }
    end

    # ruby_options > ENV > config > default
    def option_fallback(key, default = nil)
      if !ruby_options[key].nil?
        ruby_options[key]
      elsif !ENV[key].nil?
        ENV[key]
      elsif !config['options'][key].nil?
        config['options'][key]
      else
        default
      end
    end

    def set_locales
      self.locales = options['locales'] || []
      if use_i18n
        self.locales = locales & I18n.available_locales.map(&:to_s)
      end
    end

    def set_default_locale
      self.default_locale = (options['default_locale'] || (use_i18n ? I18n.default_locale : nil) || locales.first || 'en').to_s
    end

    def set_directories
      # locales directory: 1.options / 2.rails / 3.locales
      self.locales_dir = options['locales_dir'] || (use_rails ? Rails.root.join('config', 'locales') : nil) || File.join(Dir.pwd,'locales')
      Dir.mkdir(locales_dir) unless Dir.exist?(locales_dir)
      # tmp directory: 1.options / 2.rails / 3.locales
      self.tmp_dir = options['tmp_dir'] || (use_rails ? Rails.root.join('tmp') : nil) || File.join(Dir.pwd,'tmp')
      Dir.mkdir(tmp_dir) unless Dir.exist?(tmp_dir)
    end

    def use_google_drive?
      sub_translations.any?{|sub_translation| sub_translation.is_google_drive?}
    end

    def set_google_drive_manager
      self.google_drive_manager = GoogleDriveManager.new(config["google_drive_credentials"])
    end

    def set_sub_translations
      self.sub_translations = []

      existing_sub_translations = {}
      locales.each do |locale|
        # Look for local translation files (ex: locales/en/set1.yml, locales/en/set2.yml, locales/fr/set1.yml, locales/fr/set2.yml)
        existing_sub_translations[locale] = Dir[File.join(locales_dir, locale, '*.yml')].map{|f| File.basename(f)}
      end

      # Look for files declared in config
      options['files'].each do |yml_file,url|
        # If files defined, only use the defined ones
        unless options['files_only'] && !options['files_only'].include?(yml_file)
          # Set each file existing locales
          existing_locales = existing_sub_translations.select{|locale,yml_files| yml_files.include?(yml_file)}.map{|locale,yml_files| locale}
          self.sub_translations << SubTranslation.new(yml_file,url,existing_locales,self)
        end
      end
    end

  end
end
