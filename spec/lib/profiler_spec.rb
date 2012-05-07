require 'spec_helper'

describe AreWeThereYet::Profiler do
  before(:all) do
    @db_name = "/tmp/are_we_there_yet_#{Time.now.to_i}_#{rand(100000000)}_spec.sqlite"
    @db = "sqlite://#{@db_name}"

    @connection = AreWeThereYet::Persistence::Connection.create(@db)
    AreWeThereYet::Persistence::Schema.create(@connection)

    @connection[:metrics].insert_multiple(
      [
        { :path => "/path/to/spec", :description => "blah", :execution_time => 5, :run_id => 1 },
        { :path => "/path/to/spec", :description => "blaah", :execution_time => 10, :run_id => 1 },
        { :path => "/path/to/other/spec", :description => "asdfghij", :execution_time => 5, :run_id => 1 },
        { :path => "/path/to/spec", :description => "blah", :execution_time => 18, :run_id => 2 },
        { :path => "/path/to/spec", :description => "blaah", :execution_time => 30, :run_id => 2 },
      ]
    )

    @profiler = AreWeThereYet::Profiler.new(@db)
  end

  after(:all) do
    @connection.disconnect
    File.unlink(@db_name) if File.exists? @db_name
  end

  it "returns a list of the spec files ordered by descending average execution time" do
    file_list = @profiler.list_files
    file_list.should == [
      { :file => "/path/to/spec", :average_execution_time => 31.5 },
      { :file => "/path/to/other/spec", :average_execution_time => 5.0 },
    ]
  end

  it "returns a sorted list of examples together with run times for a given file" do
    examples_for_file = @profiler.list_examples("/path/to/spec")
    examples_for_file.should == [
      { :example => "blaah", :average_execution_time => 20.0 },
      { :example => "blah", :average_execution_time => 11.5 }
    ]
  end

  it "returns an empty list of examples if the given file path cannot be found" do
    examples_for_file = @profiler.list_examples("/un/known/file")

    examples_for_file.should respond_to :each
    examples_for_file.should be_empty
  end
end
