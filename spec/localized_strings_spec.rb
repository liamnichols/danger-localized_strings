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
      end

      it "should error when no files are found" do
        allow(Dir).to receive(:glob).and_return []
        @localized_strings.verify("Localizable", "en")
        expect(@dangerfile.status_report[:errors]).to eq(["Unable to find any strings files matching `./**/Localizable.strings`"])
      end

      it "should work with specified search_path" do
        allow(Dir).to receive(:glob).and_return []
        @localized_strings.verify("Localizable", "en", nil, "/Foo/Bar")
        expect(@dangerfile.status_report[:errors]).to eq(["Unable to find any strings files matching `/Foo/Bar/**/Localizable.strings`"])
      end

      it "should allow search_path to have a trailing slash" do
        allow(Dir).to receive(:glob).and_return []
        @localized_strings.verify("Localizable", "en", nil, "/Foo/Bar/")
        expect(@dangerfile.status_report[:errors]).to eq(["Unable to find any strings files matching `/Foo/Bar/**/Localizable.strings`"])
      end
    end
  end
end
