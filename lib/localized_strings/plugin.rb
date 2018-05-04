# frozen_string_literal: true

require "json"

module Danger
  #
  #
  class DangerLocalizedStrings < Plugin
    # The development language set in the project. This property must be set for the plugin to work.
    attr_accessor :development_language

    # An array of expected languages. Setting this property will cause the validator to ensure that
    #  there are strings files present and valid for the given languages specifically. If a language
    #  is missing or if there are different langues, warnings will be generated. Default value is nil.
    attr_accessor :expected_languages

    # Ignores checks to ensure that the key of a string is not present in the value of the string when set to `true`.
    attr_accessor :ignore_if_key_is_value

    # Verify
    # @returns [void]
    #
    def verify(file_name, search_path = ".")
      # Ensure the @development_language was set
      return fail "development_lanugage has not been set" if @development_language.nil?

      # Find all of the .strings files with the name provided
      found_file_paths = find_strings_files(search_path, file_name)
      return unless found_file_paths.count.positive?

      # Map to a hash of languages and their paths
      translations = {}
      found_file_paths.each do |path|
        lang = path.split("/").select { |s| s.end_with? ".lproj" }[0].sub ".lproj", "" # TODO: probably do this better
        translations[lang] = path
      end

      # Check that the development language was found
      return fail "Unable to find strings file for development_language. Missing file `#{development_language}.lproj/#{file_name}.strings`" if translations[@development_language].nil?

      # Check for the expected languages if they've been provided
      unless @expected_languages.nil?
        result = compare_languages(@expected_languages, translations.keys, file_name)
        return unless result[:should_continue]
      end

      # Get the translations for the development language
      development_strings = load_plist(translations[development_language])

      # Loop each plist
      translations.each do |language, file_path|
        # Make sure that the plist is valid
        unless valid_plist(file_path)
          warn "Invalid plist file '#{file_path}'"
          next
        end

        # Load the translations
        strings = load_plist(file_path)

        # Check for bad values if enabled
        check_for_values_as_keys(strings, file_name, language) unless @ignore_if_key_is_value

        # No point comparing the development language
        next unless language != development_language

        # Compare the translations
        compare_translations(development_strings, strings, file_name, language)
      end

      message "Successfully verified #{development_strings.count} strings across #{translations.count} languages"
    end

    # Finds the given .strings files with a matching name in the given search path.
    # If there are no results then a failure is logged.
    #
    # @returns Array<String>
    #
    def find_strings_files(search_path, file_name)
      search_query = File.join(search_path, "**", "#{file_name}.strings")
      results = Dir.glob(search_query)
      fail "Unable to find any strings files matching `#{search_query}`" unless results.count.positive?
      results
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
        fail "Unable to find strings file named `#{file_name}.strings` for language `#{language}`"
      end

      # Warn about any extra strings files that we found
      unexpected.each do |language|
        fail "Found unexpected strings file named `#{file_name}.strings` for language `#{language}`"
      end

      # Return the results as well
      {
        missing: missing,
        unexpected: unexpected,
        should_continue: missing.count.zero? && unexpected.count.zero?
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
        missing: missing,
        unexpected: unexpected
      }
    end

    # Checks the key and value of each hash and errors if the value == key
    #
    def check_for_values_as_keys(strings, file_name, language)
      strings.each do |key, value|
        fail "String `#{key}` value matches key in `#{file_name}.strings` for language `#{language}`" if key == value
      end
    end

    # Makes sure that the given plist is valid
    #
    def valid_plist(file_path)
      result = `plutil -lint "#{file_path}" | grep ": OK" -c` # TODO: nicer way to do this?
      result == "1\n"
    end

    # Loads the plist at a given path
    #
    def load_plist(file_path)
      json_data = `plutil -convert json -o - "#{file_path}"`
      JSON.parse(json_data)
    end

    private :find_strings_files, :compare_languages, :compare_translations, :check_for_values_as_keys, :valid_plist, :load_plist
  end
end
