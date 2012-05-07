require 'spec_helper'

describe AreWeThereYet::ProfilerUI do
  before(:all) do
    @db_name = "/tmp/are_we_there_yet_#{Time.now.to_i}_#{rand(100000000)}_spec.sqlite"
    @db = "sqlite://#{@db_name}"
    @connection = AreWeThereYet::Persistence::Connection.create(@db)
    AreWeThereYet::Persistence::Schema.create(@connection)

    @path = "/path/to/spec"
    @time = 9.5
    @description = "blaah"

    @connection[:metrics].insert(:path => @path, :description => @description, :execution_time => @time, :run_id => 1)
  end

  before(:each) do
    @mock_io = double(IO)
  end

  after(:all) do
    @connection.disconnect
    File.unlink(@db_name) if File.exists? @db_name
  end

  context "file listing" do
    it "writes a file listing togther with headers to STDOUT" do
      output_matcher = /File Path.*Average Execution Time.*\n\n.*#{@path}.*#{@time}\n/
      @mock_io.should_receive(:write).with(output_matcher)

      AreWeThereYet::ProfilerUI.get_profiler_output(@db, @mock_io, :list => 'files')
    end
  end

  context "example listing" do
    it "outputs an example listing for a given file" do
      output_matcher = /Example.*Average Execution Time.*\n\n.*#{@description}.*#{@time}\n/
      @mock_io.should_receive(:write).with(output_matcher)

      AreWeThereYet::ProfilerUI.get_profiler_output(@db, @mock_io, :list => 'examples', :file_path => '/path/to/spec')
    end
  end

  context "unknown listing" do
    it "raises an exception" do
      expect { AreWeThereYet::ProfilerUI.get_profiler_output(@db, @mock_io, :list => 'awesome') }.
        should raise_error AreWeThereYet::ProfilerUI::UnknownListingError
    end
  end
end
