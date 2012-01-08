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
      @mock_example = mock(Example, :location => "/path/to/spec")
    end

    it "creates an entry for the example's location" do
      @awty.example_passed(@mock_example)

      locations = SQLite3::Database.new(@db_name).execute("SELECT * FROM locations")
      locations.size.should == 1
    end
  end
end
