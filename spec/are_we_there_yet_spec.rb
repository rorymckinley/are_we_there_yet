# require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'spec_helper'

describe AreWeThereYet do
  before(:each) do
    @db_name = "#{Time.now.to_f}.sqlite"
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
      table_exists?(@db_name, 'metrics').should be_true
    end

    it "does not create the tables if they already exist"
  end
end
