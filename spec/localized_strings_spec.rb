require File.expand_path("../spec_helper", __FILE__)

module Danger
  describe Danger::DangerLocalizedStrings do
    it "should be a plugin" do
      expect(Danger::DangerLocalizedStrings.new(nil)).to be_a Danger::Plugin
    end

    #
    # Test the plugin within a Dangerfile
    #
    describe "with Dangerfile" do
      before do
        @dangerfile = testing_dangerfile
        @localized_strings = @dangerfile.localized_strings
        @localized_strings.development_language = "en"
      end

      it "should error if the development_language is not set" do
        allow(Dir).to receive(:glob).and_return []
        @localized_strings.development_language = nil
        @localized_strings.verify "Localizable"
        expect(@dangerfile.status_report[:errors]).to eq(["development_lanugage has not been set"])
        expect(@dangerfile.status_report[:warnings]).to eq([])
        expect(@dangerfile.status_report[:messages]).to eq([])
      end

      it "should error when no files are found" do
        allow(Dir).to receive(:glob).and_return []
        @localized_strings.verify "Localizable"
        expect(@dangerfile.status_report[:errors]).to eq(["Unable to find any strings files matching `./**/Localizable.strings`"])
        expect(@dangerfile.status_report[:warnings]).to eq([])
        expect(@dangerfile.status_report[:messages]).to eq([])
      end

      it "should work with specified search_path" do
        allow(Dir).to receive(:glob).and_return []
        @localized_strings.verify("Localizable", nil, "/Foo/Bar")
        expect(@dangerfile.status_report[:errors]).to eq(["Unable to find any strings files matching `/Foo/Bar/**/Localizable.strings`"])
        expect(@dangerfile.status_report[:warnings]).to eq([])
        expect(@dangerfile.status_report[:messages]).to eq([])
      end

      it "should allow search_path to have a trailing slash" do
        allow(Dir).to receive(:glob).and_return []
        @localized_strings.verify("Localizable", nil, "/Foo/Bar/")
        expect(@dangerfile.status_report[:errors]).to eq(["Unable to find any strings files matching `/Foo/Bar/**/Localizable.strings`"])
        expect(@dangerfile.status_report[:warnings]).to eq([])
        expect(@dangerfile.status_report[:messages]).to eq([])
      end

      it "should error with missing development_language" do
        search_path = File.join(Dir.pwd, "spec", "resources", "missing_development_language")
        @localized_strings.verify("Localizable", nil, search_path)
        expect(@dangerfile.status_report[:errors]).to eq(["Unable to find strings file for development_language. Missing file `en.lproj/Localizable.strings`"])
        expect(@dangerfile.status_report[:warnings]).to eq([])
        expect(@dangerfile.status_report[:messages]).to eq([])
      end

      it "should error due to missing language" do
        search_path = File.join(Dir.pwd, "spec", "resources", "valid")
        @localized_strings.verify("Localizable", ["en", "es", "fr", "ar"], search_path)
        expect(@dangerfile.status_report[:errors]).to eq(["Unable to find strings file named `Localizable.strings` for language `ar`"])
        expect(@dangerfile.status_report[:warnings]).to eq([])
        expect(@dangerfile.status_report[:messages]).to eq([])
      end

      it "should error due to unexpected language" do
        search_path = File.join(Dir.pwd, "spec", "resources", "valid")
        @localized_strings.verify("Localizable", ["en", "es"], search_path)
        expect(@dangerfile.status_report[:errors]).to eq(["Found unexpected strings file named `Localizable.strings` for language `fr`"])
        expect(@dangerfile.status_report[:warnings]).to eq([])
        expect(@dangerfile.status_report[:messages]).to eq([])
      end

      it "should not error when the language files are found" do
        search_path = File.join(Dir.pwd, "spec", "resources", "valid")
        @localized_strings.verify("Localizable", ["en", "es", "fr"], search_path)
        expect(@dangerfile.status_report[:errors]).to eq([])
        expect(@dangerfile.status_report[:warnings]).to eq([])
        expect(@dangerfile.status_report[:messages]).to eq(["Successfully verified 1 strings across 3 languages"])
      end

      it "should error when a key is found in the value" do
        search_path = File.join(Dir.pwd, "spec", "resources", "key_for_value")
        @localized_strings.verify("Localizable", ["en", "es", "fr"], search_path)
        expect(@dangerfile.status_report[:errors]).to eq(["String `identifier_for_string_foo` value matches key in `Localizable.strings` for language `en`"])
        expect(@dangerfile.status_report[:warnings]).to eq([])
        expect(@dangerfile.status_report[:messages]).to eq(["Successfully verified 1 strings across 3 languages"])
      end

      it "should not error when a key is found in the value if ignore_if_key_is_value is set" do
        search_path = File.join(Dir.pwd, "spec", "resources", "key_for_value")
        @localized_strings.ignore_if_key_is_value = true
        @localized_strings.verify("Localizable", ["en", "es", "fr"], search_path)
        expect(@dangerfile.status_report[:errors]).to eq([])
        expect(@dangerfile.status_report[:warnings]).to eq([])
        expect(@dangerfile.status_report[:messages]).to eq(["Successfully verified 1 strings across 3 languages"])
      end
    end
  end
end
