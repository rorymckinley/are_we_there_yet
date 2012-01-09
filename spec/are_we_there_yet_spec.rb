require 'spec_helper'

describe AreWeThereYet do
  before(:each) do
    @db_name = "/tmp/arewethereyet.sqlite"
    File.unlink(@db_name) if File.exists? @db_name
  end

  it "extends the RSpec formatter" do
    AreWeThereYet.should < Spec::Runner::Formatter::BaseFormatter
  end

  describe "#initialize" do
    it "opens a connection to the specified database" do
      SQLite3::Database.should_receive(:new).with('/path/to/db.sqlite').and_return(mock(SQLite3::Database).as_null_object)
      AreWeThereYet.new({},'/path/to/db.sqlite')
    end

    it "creates the necessary tables in the database" do
      AreWeThereYet.new({},@db_name)
      table_exists?(@db_name, 'locations').should be_true
      table_exists?(@db_name, 'examples').should be_true
      table_exists?(@db_name, 'metrics').should be_true
    end

    it "creates the necessary indexes" do
      AreWeThereYet.new({},@db_name)
      index_exists?(@db_name, 'locations', 'path').should be_true
      index_exists?(@db_name, 'examples', 'location_description').should be_true
    end

    it "does not create the tables if they already exist" do
      AreWeThereYet.new({},@db_name)
      SQLite3::Database.any_instance.should_not_receive(:execute)

      AreWeThereYet.new({}, @db_name)
    end

    it "rolls back table creation on error" do
      connection = SQLite3::Database.new(@db_name)
      connection.stub(:execute) do |arg|
        if arg =~ /metrics/
          raise RuntimeError
        else
          connection.execute2(arg)
          []
        end
      end
      SQLite3::Database.should_receive(:new).and_return(connection)

      expect { AreWeThereYet.new({},@db_name) }.should raise_error

      connection.execute2("SELECT name FROM sqlite_master").size.should == 1 # Execute2 lists fields - size 1 means empty response
    end
  end

  describe "logging a metric for a new location" do
    before(:each) do
      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec:42", :description => "blaah")
    end

    it "creates an entry for the example's location" do
      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      locations = SQLite3::Database.new(@db_name).execute("SELECT id, path FROM locations")
      locations.size.should == 1
      locations.first[1].should == @mock_example.location.split(':').first
    end

    it "creates an entry for the example itself" do
      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      connection = SQLite3::Database.new(@db_name)
      location = connection.get_first_row("SELECT id FROM locations")
      location_id = location.first
      examples = connection.execute("SELECT id, location_id, description FROM examples")

      examples.size.should == 1
      examples.first[1].should == location_id
      examples.first[2].should == @mock_example.description
    end

    it "creates an entry for the total execution time" do
      start_time = Time.now - 10
      end_time = Time.now

      Time.should_receive(:now).and_return(start_time)
      @awty.example_started(@mock_example)

      Time.should_receive(:now).and_return(end_time)
      @awty.example_passed(@mock_example)

      connection = SQLite3::Database.new(@db_name)
      example = connection.get_first_row("SELECT id FROM examples")
      example_id = example.first

      Time.stub!(:now)
      metrics = connection.execute("SELECT id, example_id, execution_time, created_at FROM metrics")
      metrics.size.should == 1
      metrics.first[1].should == example_id
      metrics.first[2].should == end_time - start_time
      metrics.first[3].should_not be_nil
    end
  end

  describe "logging a metric for an existing location" do
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

      connection = SQLite3::Database.new(@db_name)

      examples = connection.execute("SELECT description FROM examples")
      examples.size.should == 2

      locations = connection.execute("SELECT id FROM locations")
      locations.size.should == 1
    end
  end

  describe "logging a metric for an existing example" do
    before(:each) do
      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
    end

    it "creates an example linked to the existing location" do
      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      @awty.example_started(@mock_example)
      @awty.example_passed(@mock_example)

      connection = SQLite3::Database.new(@db_name)

      metrics = connection.execute("SELECT id FROM metrics")
      metrics.size.should == 2

      examples = connection.execute("SELECT description FROM examples")
      examples.size.should == 1
    end
  end

  describe "handling errors when logging" do
    before(:each) do
      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
      @awty.example_started(@mock_example)
    end

    it "allows the error through and any changes are undone" do
      connection = SQLite3::Database.new(@db_name)
      connection.execute("DROP TABLE metrics")

      expect { @awty.example_passed(@mock_example) }.should raise_error

      connection.execute("SELECT * FROM locations").should be_empty
      connection.execute("SELECT * FROM examples").should be_empty
    end
  end
end
