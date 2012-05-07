require 'spec_helper'

describe AreWeThereYet::Persistence::Connection do
  before(:each) do
    @db_name = "/tmp/arewethereyet.sqlite"
    @db = "sqlite://#{@db_name}"

    File.unlink(@db_name) if File.exists? @db_name
  end

  it "returns a connection object for the database uri provided" do
    db = AreWeThereYet::Persistence::Connection.create(@db)
    db.url.should == "sqlite:/#{@db_name}"
    db.test_connection.should be_true
  end

  it "raises an error if it cannot connect to the URI specified" do
    expect { AreWeThereYet::Persistence::Connection.create('obviously_bogus') }.
      should raise_error(AreWeThereYet::Persistence::Connection::InvalidDBLocation, /check that the location is valid/)
  end
end
