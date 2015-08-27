# encoding: utf-8
Gem::Specification.new do |s|
  s.name        = 'i18n-docs'
  s.version     = '0.0.8a'
  s.date        = '2015-06-12'
  s.summary     = "Maintain translations in Google Docs and import them to your Rails/non-Rails project."
  s.description = "GEM providing helper scripts to manage i18n translations in Google Docs. Features: check YAML files for missing translations; export YAML files to CSV; download translations from multiple Google spreadsheets and store to YAML files"
  s.authors     = ["Georg Kunz", "Ivan Jovanovic", "Jeremy Seitz", "Eduard Schäli", "Robin Wunderlin", "Esteban Pastorino", "Antoine Censi", "Michael Wood"]
  s.email       = 'jeremy.seitz@local.ch'
  s.files       = Dir["lib/**/*.rb","lib/tasks/*.rake"]
  s.homepage    = 'https://github.com/AntoineInsa/i18n-docs'
  s.license     = 'MIT'

  # dependencies
  s.add_dependency('rake')
  s.add_dependency('google-api-client', '~> 0.8.2')
  s.add_dependency('google_drive', '~> 1.0.0')

  s.add_development_dependency('pry')
  s.add_development_dependency('rspec')
  s.add_development_dependency('guard-rspec')
  s.add_development_dependency('awesome_print')
end
