# require 'rake'

# load rake tasks in case GEM is included within rails project

require 'csv'
require 'yaml'
require 'open-uri'

require 'rubygems'
require 'google/api_client'
require 'google_drive'

require 'i18n-docs/utils'
require 'i18n-docs/missing_keys_finder'
require 'i18n-docs/translations_manager'
require 'i18n-docs/sub_translation'
require 'i18n-docs/google_drive_manager'

if defined?(Rails)
  class LocalchI18nTask < Rails::Railtie
    rake_tasks do
      Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')].each { |f| load f }
    end
  end
end

