require 'spec_helper'

describe AreWeThereYet::File do
  it "uses the file path as the string representation of a file" do
    f = AreWeThereYet::File.new
    f.path = "/path/to/spec"
    f.to_s.should eq f.path
  end
end
