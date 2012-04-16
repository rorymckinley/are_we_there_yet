require 'spec_helper'

describe AreWeThereYet::Profiler do
  before(:each) do
    @db_name = "/tmp/are_we_there_yet_#{Time.now.to_i}_#{rand(100000000)}_spec.sqlite"
    @db = "sqlite://#{@db_name}"
  end

  after(:each) do
    File.unlink(@db_name) if File.exists? @db_name
  end

  it "raises an error if the URI provided is not valid" do
    expect { AreWeThereYet::Profiler.new('/this/is/obviously/bogus') }.
        should raise_error(AreWeThereYet::InvalidDBLocation, /check that the location is valid/)
  end

  it "returns a list of the spec files ordered by descending average execution time" do
    metric_sets = { :runs => [
      [
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 10 },
        { :location => "/path/to/spec", :description => "blaah_some_more", :execution_time => 5 },
        { :location => "/path/to/other/spec", :description => "asdfghij", :execution_time => "5" }
      ],
      [
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 30 },
        { :location => "/path/to/spec", :description => "blaah_some_more", :execution_time => 19 },
      ]
    ]}
    MetricFactory.new(@db).add_metrics(metric_sets)

    profiler = AreWeThereYet::Profiler.new(@db)
    file_list = profiler.list_files
    file_list.should == [
      { :file => "/path/to/spec", :average_execution_time => 32.0 },
      { :file => "/path/to/other/spec", :average_execution_time => 5.0 },
    ]
  end

  it "returns a sorted list of examples together with run times for a given file" do
    metric_sets = { :runs => [
      [
        { :location => "/path/to/spec", :description => "blah", :execution_time => 5 },
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 10 },
        { :location => "/path/to/other/spec", :description => "asdfghij", :execution_time => "5" }
      ],
      [
        { :location => "/path/to/spec", :description => "blah", :execution_time => 19 },
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 30 },
      ]
    ]}
    MetricFactory.new(@db).add_metrics(metric_sets)

    profiler = AreWeThereYet::Profiler.new(@db)
    examples_for_file = profiler.list_examples("/path/to/spec")
    examples_for_file.should == [
      { :example => "blaah", :average_execution_time => 20.0 },
      { :example => "blah", :average_execution_time => 12.0 }
    ]
  end

  it "returns an empty list of examples if the given file path cannot be found" do
    metric_sets = { :runs => [
      [
        { :location => "/path/to/spec", :description => "blah", :execution_time => 5 },
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 10 },
        { :location => "/path/to/other/spec", :description => "asdfghij", :execution_time => "5" }
      ],
      [
        { :location => "/path/to/spec", :description => "blah", :execution_time => 19 },
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 30 },
      ]
    ]}
    MetricFactory.new(@db).add_metrics(metric_sets)

    profiler = AreWeThereYet::Profiler.new(@db)
    examples_for_file = profiler.list_examples("/un/known/file")

    examples_for_file.should respond_to :each
    examples_for_file.should be_empty
  end
end
