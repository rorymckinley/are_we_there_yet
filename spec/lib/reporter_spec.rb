require 'spec_helper'

describe AreWeThereYet::Profiler do
  before(:each) do
    @db_name = '/tmp/writer_spec_db.sqlite'
    File.unlink(@db_name) if File.exists? @db_name
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
    MetricFactory.new(@db_name).add_metrics(metric_sets)

    profiler = AreWeThereYet::Profiler.new(@db_name)
    file_list = profiler.list_files
    file_list.should == [
      { :file => "/path/to/spec", :average_execution_time => 32.0 },
      { :file => "/path/to/other/spec", :average_execution_time => 5.0 },
    ]
  end
end
