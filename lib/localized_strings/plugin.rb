require 'json'

module Danger
  # This is your plugin class. Any attributes or methods you expose here will
  # be available from within your Dangerfile.
  #
  # To be published on the Danger plugins site, you will need to have
  # the public interface documented. Danger uses [YARD](http://yardoc.org/)
  # for generating documentation from your plugin source, and you can verify
  # by running `danger plugins lint` or `bundle exec rake spec`.
  #
  # You should replace these comments with a public description of your library.
  #
  # @example Ensure people are well warned about merging on Mondays
  #
  #          my_plugin.warn_on_mondays
  #
  # @see  Liam Nichols/danger-localized_strings
  # @tags monday, weekends, time, rattata
  #
  class DangerLocalizedStrings < Plugin

    # Verify
    #
    def verify(file_name, development_language, expected_languages = nil, search_path = ".")

      # Find all of the .strings files with the name provided
      found_file_paths = Dir.glob("#{search_path}/**/#{file_name}.strings")

      # Map to a hash of languages and their paths
      translations = {}
      found_file_paths.each do |path|
        lang = path.split("/").select { |s| s.end_with? ".lproj" }[0].sub ".lproj", "" # TODO: probably do this better
        translations[lang] = path
      end

      # Check that the development language was found
      if translations[development_language] == nil then
        fail "Unable to find strings file for development language (#{search_path}/**/#{development_language}.lproj/#{file_name}.strings)"
        return
      end

      # Check for the expected languages if they've been provided
      if expected_languages != nil then
        compare_languages(expected_languages, translations.keys, file_name)
      end

      # Get the translations for the development language
      development_strings = load_plist(translations[development_language])

      # Loop each plist
      translations.each do |language, file_path|

        # Make sure that the plist is valid
        if !is_valid_plist(file_path) then
          warn "Invalid plist file '#{file_path}'"
          next
        end

        # No point comparing the development language
        next unless language != development_language

        # Load the translations
        strings = load_plist(file_path)

        # Compare the translations
        compare_translations(development_strings, strings, file_name, language)
      end
    end

    # Compares an array of languages for a given file name and warns if any are
    #  missing or unexpected.
    #
    #
    def compare_languages(expected, actual, file_name)

      # Work out what languages are missing and what unexpected ones are present
      missing = expected - actual
      unexpected = actual - expected

      # Warn about anything that is missing
      missing.each do |language|
        warn "Unable to find strings file named '#{file_name}.strings' for language '#{language}'"
      end

      # Warn about any extra strings files that we found
      unexpected.each do |language|
        warn "Found unexpected strings file named '#{file_name}.strings' for language '#{language}'"
      end

      # Return the results as well
      {
        :missing => missing,
        :unexpected => unexpected
      }
    end

    # Compare a hash of translations
    #
    def compare_translations(expected, actual, file_name, language)

      # Work out what keys are missing and what unexpected ones are present
      missing = expected.keys - actual.keys
      unexpected = actual.keys - expected.keys

      # Warn about anything that is missing
      missing.each do |key|
        warn "Translation '#{key}' in '#{file_name}.strings' is defined in development language but not for '#{language}'"
      end

      # Warn about any extra strings files that we found
      unexpected.each do |key|
        warn "Translation '#{key}' in '#{file_name}.strings' is defined for '#{language}' but not the development language"
      end

      # Return the results as well
      {
        :missing => missing,
        :unexpected => unexpected
      }
    end

    # Makes sure that the given plist is valid
    #
    def is_valid_plist(file_path)
      result = `plutil -lint "#{file_path}" | grep ": OK" -c` # TODO: nicer way to do this?
      result == "1\n"
    end

    # Loads the plist at a given path
    #
    def load_plist(file_path)
      json_data = `plutil -convert json -o - "#{file_path}"`
      JSON.parse(json_data)
    end

    private :compare_languages, :compare_translations, :is_valid_plist, :load_plist
  end
end
