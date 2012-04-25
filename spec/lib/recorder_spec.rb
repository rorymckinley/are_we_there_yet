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

      @connection.tables.sort.should == [:metrics, :runs]
    end

    it "logs the start of a spec run" do
      mock_time = Time.now
      mock_time.should_receive(:utc).and_return(mock_time)
      Time.stub(:now).and_return(mock_time)

      AreWeThereYet::Recorder.new({},@db)

      @connection[:runs].first[:started_at].should_not be_nil
    end

    it "does not log the start of a spec run if there is no table in the database" do
      # This to maintain backwards-compatibility with DBs created by v0.1.0
      broken_connection = mock(Sequel::SQLite::Database, :tables => @connection.tables, :transaction => nil)
      broken_connection.stub(:create_table) do |arg, bl|
        if arg == :metrics
          # Do nothing - runs table is not created
        else
          @connection.create_table(arg, &bl)
        end
      end
      Sequel.should_receive(:connect).and_return(broken_connection)

      expect { AreWeThereYet::Recorder.new({},@db) }.should_not raise_error
    end
  end

  describe "logging a metric for a new file" do
    before(:each) do

      @awty = AreWeThereYet::Recorder.new({}, @db)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec:42", :description => "blaah")
    end

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
      metric[:created_at].should_not be_nil
      metric[:run_id].should == run_id
      metric[:path].should == @mock_example.location.split(':').first
      metric[:description].should == @mock_example.description
    end

    it "allows the observed execution time to be overridden" do
      start_time = Time.now - 10
      end_time = Time.now

      Time.stub!(:now).and_return(start_time)
      @awty.example_started(@mock_example)

      Time.stub!(:now).and_return(end_time)
      @awty.example_passed(@mock_example, :execution_time => 999.99)

      @connection[:metrics].count.should ==1
      metric = @connection[:metrics].first
      metric[:execution_time].should == 999.99
    end

    it "tracks metric creation using UTC time" do
      mock_time = Time.now
      utc_time = Time.now - 7200
      mock_time.should_receive(:utc).and_return(utc_time)
      Time.stub(:now).and_return(mock_time)

      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      @connection[:metrics].first[:created_at].should == utc_time
    end

    it "does not link the metric to a run if the run table does not exist" do
      # To maintain compatibility with version 0.1.0
      AreWeThereYet::Recorder.any_instance.should_receive(:tracking_runs?).and_return(false)

      @connection.create_table!(:metrics) do
        primary_key :id
        Integer :example_id
        Float :execution_time
        DateTime :created_at
        String :path
        String :description
      end

      @awty.example_started(@mock_example)
      expect { @awty.example_passed(@mock_example) }.should_not raise_error
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

      run = @connection[:runs].first
      run[:ended_at].should_not be_nil
    end

    it "stores the UTC time value for the relevant run" do
      time = Time.now
      time.should_receive(:utc).and_return(time - 7200)
      Time.stub(:now).and_return(time)

      @awty.close
    end

    it "does not update the run if runs are not being tracked" do
      @connection.drop_table(:runs)
      AreWeThereYet::Recorder.any_instance.should_receive(:tracking_runs?).and_return(false)

      expect { @awty.close }.should_not raise_error
    end
  end
end
