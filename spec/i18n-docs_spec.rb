require 'spec_helper'
require 'pry'

include Helpers

# High level integration specs
describe I18nDocs do
  describe "I18nDocs::TranslationsManager.import_translations" do
    it 'imports the right translations' do
      output_path = File.join(fixture_path,'output')

      options = {
        'default_locale'      => ['en'],
        'locales'             => ['en','fr','de'],
        'files'               => {'activities.yml' => File.join(fixture_path, 'csv', 'translations.csv')},
        'cleanup'             => true,
        'debugger'            => false,

        'i18n-docs-path'      => fixture_path,

        'tmp_dir'             => 'tmp',
        'locales_dir'         => output_path,
        'single_locale_file'  => true,
        'include_locale_key'  => true,
        'force_fallback'      => true,
      }

      I18nDocs::TranslationsManager.import_translations(options)

      expected_translations = {
        'en' => {
          'numbers' => {
            'one'   => 'one',
            'two'   => 'two',
            'three' => 'three'
          }
        }
      }
      original_translation = YAML.load_file(File.join(output_path,'en.yml'))
      expect(original_translation).to eq(expected_translations)

      expected_translations = {
        'fr' => {
          'numbers' => {
            'one'   => 'un',
            'two'   => 'deux',
            'three' => 'trois'
          }
        }
      }
      original_translation = YAML.load_file(File.join(output_path,'fr.yml'))
      expect(original_translation).to eq(expected_translations)

      remove_output_dir
    end
  end

  describe "I18nDocs::TranslationsManager.export_translations" do
    it 'exports the right translations' do
      output_path = File.join(fixture_path,'output')

      options = {
        'default_locale'      => 'en',
        'locales'             => ['en','fr','de'],
        'files'               => {'activities.yml' => File.join(output_path, 'translations.csv')},
        'cleanup'             => true,
        'debugger'            => false,

        'i18n-docs-path'      => fixture_path,

        'tmp_dir'             => 'tmp',
        'locales_dir'         => File.join(fixture_path,'yml'),
        'single_locale_file'  => true,
        'include_locale_key'  => true,
        'force_fallback'      => true,
      }

      I18nDocs::TranslationsManager.export_translations(options)

      csv = File.read(File.join(output_path,'translations.csv'))

      expected_csv = """key,en,fr,de
numbers.one,one,un,eins
numbers.three,three,trois,drei
numbers.two,two,deux,zwei
"""

      expect(csv).to eq(expected_csv)

      remove_output_dir
    end
  end
end
