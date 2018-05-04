# danger-localized_strings

danger-localized_strings is a Danger plugin that provides validation methods to catch missing or invalid localizations in your projects.

This plugin exposes a simple `verify` function that can do the following:

- Validate strings files are valid plist format
- Ensure that expected localization languages are present
- Check that all keys from the development language are present in the localized languages
- Ensure that no localized value of a translation is set to the `key` by mistake (A common issue that can occour during xcodebuild imports).

## Installation

    $ gem install danger-localized_strings

## Usage

    localized_strings.ignore_if_key_is_value = false
    localized_strings.verify("Localizable", "en", ["en", "es", "fr"], "./Example/SupportingFiles/")

## Development

1. Clone this repo
2. Run `bundle install` to setup dependencies.
3. Run `bundle exec rake spec` to run the tests.
4. Use `bundle exec guard` to automatically have tests run as you make changes.
5. Make your changes.
