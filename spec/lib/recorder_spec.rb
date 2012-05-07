require 'spec_helper'

describe AreWeThereYet::Recorder do
  before(:each) do
    @db_name = "/tmp/arewethereyet.sqlite"
    @db = "sqlite://#{@db_name}"

    File.unlink(@db_name) if File.exists? @db_name

    @connection = Sequel.connect(@db)
  end

  it "extends the RSpec formatter" do
    AreWeThereYet::Recorder.should < Spec::Runner::Formatter::BaseFormatter
  end

  describe "#initialize" do
    it "creates the necessary tables in the database" do
      AreWeThereYet::Recorder.new({},@db)

      @connection.tables.should_not be_empty
    end

    it "logs the start of a spec run" do
      AreWeThereYet::Recorder.new({},@db)

      @connection[:runs].first[:started_at].should_not be_nil
    end
  end

  describe "logging a metric" do
    before(:each) do
      @awty = AreWeThereYet::Recorder.new({}, @db)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec:42", :description => "blaah")
    end

    # This test duplicates a test done for the Metric class - still undecided whether the cost of duplication
    # outweighs the benefit of confirming integration
    it "creates an entry for the metric in the database" do
      start_time = Time.now - 10
      end_time = Time.now

      Time.stub!(:now).and_return(start_time)
      @awty.example_started(@mock_example)

      Time.stub!(:now).and_return(end_time)
      @awty.example_passed(@mock_example)

      run_id = @connection[:runs].first[:id]

      @connection[:metrics].count.should ==1
      metric = @connection[:metrics].first
      metric[:execution_time].should == end_time - start_time
      metric[:run_id].should == run_id
      metric[:path].should == @mock_example.location.split(':').first
      metric[:description].should == @mock_example.description
    end
  end

  describe "closing" do
    before(:each) do
      @awty = AreWeThereYet::Recorder.new({}, @db)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
      @awty.example_started(@mock_example)
    end

    it "closes the connection to the database" do
      Sequel::SQLite::Database.any_instance.should_receive(:disconnect)
      @awty.close
    end

    it "updates the end time value for the relevant run" do
      @awty.close

      run = @connection[:runs].first[:ended_at].should_not be_nil
    end
  end
end
