require 'spec_helper'

describe AreWeThereYet::SpecFile do
  before(:each) do
    @db_name = "/tmp/are_we_there_yet_#{Time.now.to_i}_#{rand(100000000)}_spec.sqlite"
  end

  after(:each) do
    File.unlink(@db_name) if File.exists? @db_name
  end

  it "uses the file path as the string representation of a file" do
    f = AreWeThereYet::SpecFile.new
    f.path = "/path/to/spec"
    f.to_s.should eq f.path
  end

  it "retrieves an instance of itself based on the file path" do
    metric_sets = { :runs => [
      [
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 10 },
        { :location => "/path/to/spec", :description => "blaah_some_more", :execution_time => 5 },
      ],
    ]}
    MetricFactory.new(@db_name).add_metrics(metric_sets)

    f = AreWeThereYet::SpecFile.for_path("/path/to/spec")
    f.path.should eql "/path/to/spec"
  end

  it "maintains a collection of all its examples" do
    pending
    metric_sets = { :runs => [
      [
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 10 },
        { :location => "/path/to/spec", :description => "blaah_some_more", :execution_time => 5 },
      ],
    ]}
    MetricFactory.new(@db_name).add_metrics(metric_sets)
  end
end
