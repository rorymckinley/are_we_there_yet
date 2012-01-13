require 'spec_helper'

describe AreWeThereYet do
  before(:each) do
    @db_name = "/tmp/arewethereyet.sqlite"
    File.unlink(@db_name) if File.exists? @db_name

    @connection = Sequel.connect("sqlite://#{@db_name}")
  end

  it "extends the RSpec formatter" do
    AreWeThereYet.should < Spec::Runner::Formatter::BaseFormatter
  end

  describe "#initialize" do
    it "creates the necessary tables in the database" do
      AreWeThereYet.new({},@db_name)

      @connection.tables.sort.should == [:examples, :files, :metrics, :runs]
    end

    it "creates the necessary indexes" do
      AreWeThereYet.new({},@db_name)

      @connection.indexes(:files).should == { :files_path_index => {:unique=>false, :columns=>[:path]}}
      @connection.indexes(:examples).should == {
          :examples_file_id_description_index => {:unique=>false, :columns=>[:file_id, :description]}
      }
    end

    it "does not create the tables if they already exist" do
      AreWeThereYet.new({},@db_name)
      SQLite3::Database.any_instance.should_not_receive(:execute)

      AreWeThereYet.new({}, @db_name)
    end

    it "rolls back table creation on error" do
      broken_connection = mock(Sequel::SQLite::Database, :tables => [])
      broken_connection.stub(:create_table) do |arg, bl|
        if arg == :metrics
          raise RuntimeError
        else
          @connection.create_table(arg, &bl)
        end
      end
      Sequel.should_receive(:connect).and_return(broken_connection)

      expect { AreWeThereYet.new({},@db_name) }.should raise_error

      @connection.tables.should be_empty
    end

    it "logs the start of a spec run" do
      mock_time = Time.now
      mock_time.should_receive(:utc).and_return(mock_time)
      Time.stub(:now).and_return(mock_time)

      AreWeThereYet.new({},@db_name)

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

      expect { AreWeThereYet.new({},@db_name) }.should_not raise_error
    end
  end

  describe "logging a metric for a new file" do
    before(:each) do

      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec:42", :description => "blaah")
    end

    it "creates an entry for the example's file" do
      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      files = SQLite3::Database.new(@db_name).execute("SELECT id, path FROM files")
      files.size.should == 1
      files.first[1].should == @mock_example.location.split(':').first
    end

    it "creates an entry for the example itself" do
      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      file_id = @connection[:files].first[:id]

      @connection[:examples].count.should == 1
      @connection[:examples].first[:file_id].should == file_id
      @connection[:examples].first[:description].should == @mock_example.description
    end

    it "creates an entry for the total execution time" do
      start_time = Time.now - 10
      end_time = Time.now

      Time.stub!(:now).and_return(start_time)
      @awty.example_started(@mock_example)

      Time.stub!(:now).and_return(end_time)
      @awty.example_passed(@mock_example)

      run_id = @connection[:runs].first[:id]
      example_id = @connection[:examples].first[:id]

      @connection[:metrics].count.should ==1
      metric = @connection[:metrics].first
      metric[:example_id].should == example_id
      metric[:execution_time].should == end_time - start_time
      metric[:created_at].should_not be_nil
      metric[:run_id].should == run_id
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
      AreWeThereYet.any_instance.should_receive(:tracking_runs?).and_return(false)

      @connection.create_table!(:metrics) do
        primary_key :id
        Integer :example_id
        Float :execution_time
        DateTime :created_at
      end

      @awty.example_started(@mock_example)
      expect { @awty.example_passed(@mock_example) }.should_not raise_error
    end
  end

  describe "logging a metric for an existing file" do
    before(:each) do
      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
      @another_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "yippee!")
    end

    it "creates an example linked to the existing location" do
      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      @awty.example_started(@another_example)
      @awty.example_passed(@another_example)

      @connection[:examples].count.should == 2
      @connection[:files].count.should == 1
    end
  end

  describe "logging a metric for an existing example" do
    before(:each) do
      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
    end

    it "creates a metric linked to the example" do
      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      @connection[:metrics].count.should == 2
      @connection[:examples].count.should == 1
    end
  end

  describe "handling errors when logging" do
    before(:each) do
      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
      @awty.example_started(@mock_example)
    end

    it "allows the error through and any changes are undone" do
      @connection.drop_table(:metrics)

      expect { @awty.example_passed(@mock_example) }.should raise_error

      @connection[:files].count.should == 0
      @connection[:examples].count.should == 0
    end
  end

  describe "closing" do
    before(:each) do
      @awty = AreWeThereYet.new({}, @db_name)
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
      AreWeThereYet.any_instance.should_receive(:tracking_runs?).and_return(false)

      expect { @awty.close }.should_not raise_error
    end
  end
end
