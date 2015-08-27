# rake i18n:missing_keys
# rake i18n:import_translations
# rake i18n:export_translations

namespace :i18n do
  desc "Find and list translation keys that do not exist in all locales"
  task :missing_keys => :environment do
    finder = I18nDocs::MissingKeysFinder.new(I18n.backend)
    finder.find_missing_keys
  end

  desc "Download translations from Google Drive Spreadsheet and save them to YAML files."
  task :import_translations => :environment do
    I18nDocs::TranslationsManager.import_translations()
  end

  desc "Export all language files to CSV files first, Google Drive second (only files contained in en folder are considered)"
  task :export_translations => :environment do
    I18nDocs::TranslationsManager.export_translations()
  end
end
