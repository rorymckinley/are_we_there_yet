require 'spec_helper'

describe AreWeThereYet::Profiler do
  before(:each) do
    @db_name = '/tmp/writer_spec_db.sqlite'
    File.unlink(@db_name) if File.exists? @db_name
  end

  it "returns a list of the spec files together with the average time to execute" do
    metric_sets = { :runs => [[{:location => "/path/to/spec", :description => "blaah", :execution_time => 10}]]}
    MetricFactory.new(@db_name).add_metrics(metric_sets)
    # recorder = AreWeThereYet::Recorder.new({}, @db_name)
    # mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
    # end_time = Time.now
    # start_time = end_time - 10

    # Time.stub!(:now).and_return(start_time)
    # recorder.example_started(mock_example)

    # Time.stub!(:now).and_return(end_time)
    # recorder.example_passed(mock_example)

    profiler = AreWeThereYet::Profiler.new(@db_name)
    profiler.list_files.should == [{:file => "/path/to/spec", :execution_time => 10.0}]
  end
end
