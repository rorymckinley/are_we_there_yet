require 'spec_helper'

describe AreWeThereYet do
  before(:each) do
    @db_name = "/tmp/arewethereyet.sqlite"
    File.unlink(@db_name) if File.exists? @db_name

    @connection = SQLite3::Database.new(@db_name)
    @connection2 = Sequel.connect("sqlite://#{@db_name}")
  end

  it "extends the RSpec formatter" do
    AreWeThereYet.should < Spec::Runner::Formatter::BaseFormatter
  end

  describe "#initialize" do
    it "creates the necessary tables in the database" do
      AreWeThereYet.new({},@db_name)

      @connection2.tables.sort.should == [:examples, :files, :metrics, :runs]
    end

    it "creates the necessary indexes" do
      AreWeThereYet.new({},@db_name)

      index_exists?(@db_name, 'files', 'path').should be_true
      index_exists?(@db_name, 'examples', 'file_id_description').should be_true
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
          @connection2.create_table(arg, &bl)
        end
      end
      Sequel.should_receive(:connect).and_return(broken_connection)

      expect { AreWeThereYet.new({},@db_name) }.should raise_error

      @connection.execute2("SELECT name FROM sqlite_master").size.should == 1 # Execute2 lists fields - size 1 means empty response
    end

    it "logs the start of a spec run" do
      AreWeThereYet.new({},@db_name)

      run = @connection.get_first_row("SELECT id, started_at FROM runs")
      run.should_not be_nil
      run[1].should_not be_nil
    end

    it "does not log the start of a spec run if there is no table in the database" do
      # This to maintain backwards-compatibility with DBs created by v0.1.0
      @connection.stub(:execute) do |arg|
        if arg =~ /CREATE TABLE runs/
          # Do nothing
        else
          @connection.execute2(arg)
          []
        end
      end
      SQLite3::Database.should_receive(:new).and_return(@connection)

      expect { AreWeThereYet.new({},@db_name) }.should_not raise_error
    end
  end

  describe "logging a metric for a new file" do
    before(:each) do
      @connection = SQLite3::Database.new(@db_name)

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

      file = @connection.get_first_row("SELECT id FROM files")
      file_id = file.first
      examples = @connection.execute("SELECT id, file_id, description FROM examples")

      examples.size.should == 1
      examples.first[1].should == file_id
      examples.first[2].should == @mock_example.description
    end

    it "creates an entry for the total execution time" do
      start_time = Time.now - 10
      end_time = Time.now

      Time.should_receive(:now).and_return(start_time)
      @awty.example_started(@mock_example)

      Time.should_receive(:now).and_return(end_time)
      @awty.example_passed(@mock_example)

      run = @connection.get_first_row("SELECT id FROM runs")
      run_id = run.first

      example = @connection.get_first_row("SELECT id FROM examples")
      example_id = example.first

      Time.stub!(:now)
      metrics = @connection.execute("SELECT id, example_id, execution_time, created_at, run_id FROM metrics")
      metrics.size.should == 1
      metrics.first[1].should == example_id
      metrics.first[2].should == end_time - start_time
      metrics.first[3].should_not be_nil
      metrics.first[4].should == run_id
    end

    it "does not link the metric to a run if the run table does not exist" do
      # To maintain compatibility with version 0.1.0
      AreWeThereYet.any_instance.should_receive(:tracking_runs?).and_return(false)

      @connection.execute("DROP TABLE metrics")
      @connection.execute("CREATE TABLE metrics(id INTEGER PRIMARY KEY, example_id INTEGER, execution_time FLOAT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)")

      @awty.example_started(@mock_example)
      expect { @awty.example_passed(@mock_example) }.should_not raise_error
    end
  end

  describe "logging a metric for an existing file" do
    before(:each) do
      @connection = SQLite3::Database.new(@db_name)

      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
      @another_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "yippee!")
    end

    it "creates an example linked to the existing location" do
      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      @awty.example_started(@another_example)
      @awty.example_passed(@another_example)

      examples = @connection.execute("SELECT description FROM examples")
      examples.size.should == 2

      files = @connection.execute("SELECT id FROM files")
      files.size.should == 1
    end
  end

  describe "logging a metric for an existing example" do
    before(:each) do
      @connection = SQLite3::Database.new(@db_name)

      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
    end

    it "creates a metric linked to the example" do
      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      metrics = @connection.execute("SELECT id FROM metrics")
      metrics.size.should == 2

      examples = @connection.execute("SELECT description FROM examples")
      examples.size.should == 1
    end
  end

  describe "handling errors when logging" do
    before(:each) do
      @connection = SQLite3::Database.new(@db_name)

      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
      @awty.example_started(@mock_example)
    end

    it "allows the error through and any changes are undone" do
      @connection.execute("DROP TABLE metrics")

      expect { @awty.example_passed(@mock_example) }.should raise_error

      @connection.execute("SELECT * FROM files").should be_empty
      @connection.execute("SELECT * FROM examples").should be_empty
    end
  end

  describe "closing" do
    before(:each) do
      @connection = SQLite3::Database.new(@db_name)

      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
      @awty.example_started(@mock_example)
    end

    it "closes the connection to the database" do
      SQLite3::Database.any_instance.should_receive(:close)
      @awty.close
    end

    it "updates the end time value for the relevant run" do
      @awty.close

      run = @connection.get_first_row('SELECT ended_at FROM runs')
      run.first.should_not be_nil
    end

    it "stores the UTC time value for the relevant run" do
      mock_time = mock(Time, :strftime => '1970-01-01 00:00:00')
      mock_time.should_receive(:utc).and_return(mock_time)
      Time.stub(:now).and_return(mock_time)

      @awty.close
    end

    it "does not update the run if runs are not being tracked" do
      @connection.execute("DROP TABLE runs")
      AreWeThereYet.any_instance.should_receive(:tracking_runs?).and_return(false)

      expect { @awty.close }.should_not raise_error
    end
  end
end
