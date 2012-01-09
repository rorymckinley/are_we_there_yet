# require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
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

    it "does not create the tables if they already exist" do
      AreWeThereYet.new({},@db_name)
      SQLite3::Database.any_instance.should_not_receive(:execute)

      AreWeThereYet.new({}, @db_name)
    end
  end

  describe "logging a metric for a new location" do
    before(:each) do
      @awty = AreWeThereYet.new({}, @db_name)
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec", :description => "blaah")
    end

    it "creates an entry for the example's location" do
      @awty.example_start(@mock_example)
      @awty.example_passed(@mock_example)

      locations = SQLite3::Database.new(@db_name).execute("SELECT id, path FROM locations")
      locations.size.should == 1
      locations.first[1].should == @mock_example.location
    end

    it "creates an entry for the example itself" do
      @awty.example_start(@mock_example)
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
      @awty.example_start(@mock_example)

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
      metrics.first[3].should == end_time.utc.strftime("%Y-%m-%d %H:%M:%S")
    end
  end
end
