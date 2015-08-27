
[![Gem Version](https://badge.fury.io/rb/i18n-docs.svg)](http://badge.fury.io/rb/i18n-docs)
[![Build Status](https://travis-ci.org/AntoineInsa/i18n-docs.svg?branch=master)](https://travis-ci.org/AntoineInsa/i18n-docs)
[![Test Coverage](https://codeclimate.com/github/AntoineInsa/i18n-docs/badges/coverage.svg)](https://codeclimate.com/github/AntoineInsa/i18n-docs/coverage)
[![Code Climate](https://codeclimate.com/github/AntoineInsa/i18n-docs/badges/gpa.svg)](https://codeclimate.com/github/AntoineInsa/i18n-docs)
[![Stories in Ready](https://badge.waffle.io/AntoineInsa/i18n-docs.png?label=ready&title=Ready)](https://waffle.io/AntoineInsa/i18n-docs)

# i18n-docs

**i18n-docs** is a ruby gem that helps you to keep translations stored in Google Docs. This makes it easier for translators and project members to coordinate changes and updates. In addition, the standard features of Google Docs are super handy for this process: revision tracking, authorization, publishing, etc.

This gem works as well outside of a Rails environment. You can call it any from any ruby file.

*This gem is currently in use and tested with Rails 3.1. It probably works with other 3.x versions, but probably not 2.x at the moment.*

## 1. Features

- import translations from Google Spreadsheet/Worksheet or CSV files to locales yml files (one per locale)
- export translations from local locales yml files to Google Spreadsheet/Worksheet or CSV files

### 1.1 Spreadsheet structure

The spreadsheet can either be a Google Drive spreadsheet worksheet or a CSV file.

eg: **Google Drive**
Spreadsheet name: `my-i18n`
Speadsheet key: `1GsK...Cjwfw` (see the url `https://docs.google.com/spreadsheets/d/{spreadsheet_key}/edit`)
Worksheet name: `numbers`
```
| key           | en    | fr    | de   |
|---------------|-------|-------|------|
| numbers.one   | one   | un    | eins |
| numbers.two   | two   | deux  | zwei |
| numbers.three | three | trois | drei |
```

eg: **CSV spreadsheet**
File path: `config/locales/activities.yml`
```
| key         | en   | fr      | de     |
|-------------|------|---------|--------|
| places.home | Home | Maison  | Heim   |
| places.work | Work | Travail | Arbeit |
| places.park | Park | Parc    | Park   |
```


### 1.2 Locales structure

This is the assumed file structure of the project locales:
```
locales
├── en
│   ├── numbers.yml
│   └── activities.yml
├── de
│   ├── numbers.yml
│   └── activities.yml
└── fr
    ├── numbers.yml
    └── activities.yml
```

And this is an example of one of the translated file `en/numbers.yml`:
```
---
en:
  numbers:
    one: one
    two: two
    three: three
```

## 2. Configuration

Create a configuration file called `i18n-docs.yml` as the following:

```
files:
  numbers.yml: "google-drive|1GsK...Cjwfw|numbers"
  activities.yml : "config/locales/activities.csv"
  ... etc ...

google_drive_credentials:
  oauth:
    client_id: "YOUR_ID_GOES_HERE"
    client_secret: "YOUR_SECRET_GOES_HERE"

options:
  default_locale: 'en'            # The main locale, does only count for export
  locales: ['en','fr','de']       # Subset of locales to play with
  files: {key => value}           # Files to use (overwrites `i18n-docs.yml` files)
  files_only: ['activities.yml']  # Subset of filename to use
  cleanup: false                  # Remove temporary files
  tmp_dir: 'tmp'                  # Temporary upload/download directory, default: './tmp/i18n-docs/'
  locales_dir: 'i18n'             # Final locales directory, default './_i18n' or './locales'
  single_locale_file: true        # Deal only with one file per locale (no locale subdirectories)
  include_locale_key: true        # Include the locale as a key at the root of the locale file
  force_fallback: true            # Force all translations to have a value, default: false

  # Future work
  logger_level: 0                 # Verbose?
  format: 'yml'                   # .yml or .json ? default: .yml
```

### 2.1 Files

In this section, locale files are tied with translation spreadsheets.

Google Doc spreadsheet is identified by its spreadsheet key and worksheet name with the following format:

```
google_drive|{spreadsheet_key}|{worksheet_name}
```

You can pull information from some local files by giving directly an url from where the gem is run (as `activities.yml` in the example).

### 2.2 Google Drive Credentials

To get Google OAuth client_id and secret, you can follow this link: https://console.developers.google.com/project

The first time you'll run i18n-docs, it will open a webpage with Google asking you to authorize the application. After having accepted, you'll get a authorization key.
Copy and paste the key in the prompt. The key will be saved for future calls in `.i18n-docs-access-token`.

### 2.3 Options

There's actually different ways of calling these options. You can define them:
- when calling a method in ruby, by passing options as a hash (eg: `I18nDocs::TranslationsManager.import_translations({'locales_dir' => '_i18n'})`)
- when runing a rake task, by setting env variables (eg: `locales_dir=_i18n rake i18n:export_translations`)
- or simply by writing them in `i18n-docs.yml`

The only options that is not in the config file is the directory where to find the config file!
You can specify it as a ruby or an env option with the key `i18n-docs-path`.
By default, it will look in the current directory, or in the `config` directory for a Rails app.

With `single_locale_file=true` (and with only one file specified), you'll get the following file structure:
```
locales
├── en.yml
├── fr.yml
└── de.yml
```

With `include_locale_key=false`, you'll get the following locale files eg `en/numbers.yml`:
```
---
numbers:
  one: one
  two: two
  three: three
```
Note that `en:` has disappeared from the top.

With `force_locale=true`, all blank values will be force to be present:
```
| key         | en (default) | fr     | de   |
|-------------|--------------|--------|------|
| places.home | Home         | Maison | Heim |
| places.work | Workplace    |        |      |
| places.park |              |        |      |
```
becomes
```
| key                | en (default) | fr          | de          |
|--------------------|--------------|-------------|-------------|
| places.home        | Home         | Maison      | Heim        |
| places.work        | Workplace    | Workplace   | Workplace   |
| places.castle_park | Castle park  | Castle park | Castle park |
```
Note that locales are defaulting to the default locale, and then to the humnanized key.


## 3. Usage

### 3.1 For Rails user

Add the gem to your Rails project:

    gem 'i18n-docs'

Let Rails know what locales you will be using. Add this to `config/application.rb`:

    module Web
      class Application < Rails::Application
        # add yml path
        config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '*', '*.yml').to_s]
        # locals to support:
        config.i18n.available_locales = [:en,:de,:it,:fr]
      end
    end

This defines which languages and translation files to import from a Google Spreadsheet. The content of the spreadsheets will be stored under `config/locales/`.

The following rake tasks are added by the gem to your Rails project:

* `rake i18n:export_translations`
  Export all translations files to spreadsheets (Google Drive and/or local files) (the defined default locale is the reference for files to export)
* `rake i18n:import_translations`
  Download translations from spreadsheets (Google Drive and/or local files) and save them into YAML files.

### 3.2 For non-Rails users

Pick-up any directory, add a `i18n-docs.yml` file (see 2.).

Add a Gemfile:

    source "https://rubygems.org"
    gem 'i18n-docs', :github => 'AntoineInsa/i18n-docs', :branch => 'v0.0.8'


Add a i18n-docs.rb:

    #!/usr/bin/env ruby

    require 'rubygems'
    require 'i18n-docs'

    # To import translations
    I18nDocs::TranslationsManager.import_translations()

    # To export translations
    # I18nDocs::TranslationsManager.export_translations()


You may have to install:
- Rbenv (https://github.com/sstephenson/rbenv)
- RubyGems (https://rubygems.org/pages/download)
- Bundler (http://bundler.io/)

And simply execute the file by running `bundle install` the first time, and `bundle exec ruby i18n-docs.rb`! Et voilà!


## 4. CHANGELOG

### 0.0.8

Make it work outside of a Rails environment

### 0.0.7-2

Use i18n-docs.yml (old translations.yml) configuration file for Google OAuth credentials.

### 0.0.7-1

Upgrade to OAuth before Google deprecation deadline.

### 0.0.4

Update docs, license. Push to Rubygems.org.

### 0.0.3

Open sourced: changed name and description.

### 0.0.2

Removed loading of `awesome_print` from the rake task. It was breaking download.

## 5. Contributing

1. Fork it ( https://github.com/AntoineInsa/i18n-docs/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Run the tests (`bundle exec rspec spec` or `rake`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

## 6. Credits/License

This gem is sponsored by [local.ch](http://www.local.ch/). It is licensed under the [MIT license](http://en.wikipedia.org/wiki/MIT_License). If you're a ruby developer and want to work with us in Switzerland, please check out our [jobs page](http://local-ch.github.com/).
