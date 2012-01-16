require 'spec_helper'

describe AreWeThereYet::Profiler do
  before(:each) do
    @db_name = '/tmp/writer_spec_db.sqlite'
  end

  it "returns a list of the spec files together with the average time to execute" do
    recorder = AreWeThereYet::Recorder.new({}, @db_name)
    mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
    # now = Time.now
    # Time.stub(:now).and_return(now)
    # recorder.example_started(mock_example)
    # later = now + 10
    # Time.stub(:now).and_return(later)
    end_time = Time.now
    start_time = end_time - 10

    Time.stub!(:now).and_return(start_time)
    recorder.example_started(mock_example)

    Time.stub!(:now).and_return(end_time)
    recorder.example_passed(mock_example)

    profiler = AreWeThereYet::Profiler.new(@db_name)
    profiler.list_files[:execution_time].should == end_time - start_time
    profiler.list_files.should == [{:file => "/path/to.spec", :time => end_time - start_time}]
  end
end
