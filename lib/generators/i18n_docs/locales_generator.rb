# for lang in de en it fr; do \
#     mkdir -p config/locales/$lang; \
#     touch config/locales/$lang/navigation.yml; \
#     touch config/locales/$lang/forms.yml; \
#   done
module I18nDocs
  module Generators
    class LocalesGenerator < Rails::Generators::Base
      desc "Creates Locale files for I18n-docs"

      argument     :locales,           :type => :array,      :desc => "Locale codes"

      source_root File.dirname(__FILE__) + '/templates'

      def main_flow
        locales.each do |locale|
        	self.locale = locale
          exec_template
        end
      end

      def instructions
      	say "----------------------------------"
      	say "Add this to config/application.rb:"
      	say "config.i18n.available_locales = #{available_locales}", :green
      end

      protected

      def available_locales
      	locales.map(&:to_sym).inspect
      end

      def files_src_path
      	File.join Rails.root, 'config', 'translations.yml'
      end

      def yaml
        say("Missing #{files_src_path}", :red) and exit(0) unless File.exist?(files_src_path)
      	YAML::load File.open(files_src_path)
      end

      def files
      	yaml['files'].keys
      end

      attr_accessor :locale, :file, :key, :text

      def exec_template
      	files.each do |file|      
          self.file = file
          self.key = file.gsub /\..+$/, ''	
          self.text = options[:text] || "Hello from #{locale} locale"
        	template "locale.erb", "config/locales/#{locale}/#{file}"
        end
      end
    end
  end
end
