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
    end
  end
end
