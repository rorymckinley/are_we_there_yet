require 'spec_helper'

describe AreWeThereYet::Run do
  before(:each) do
    @db_name = "/tmp/are_we_there_yet_#{Time.now.to_i}_#{rand(100000000)}_spec.sqlite"
    @db = "sqlite://#{@db_name}"

    @connection = AreWeThereYet::Persistence::Connection.create(@db)
    AreWeThereYet::Persistence::Schema.create(@connection)
  end

  describe "start" do
    it "adds a record to the database" do
      @connection[:runs].all.should be_empty

      AreWeThereYet::Run.new.start(@connection)

      @connection[:runs].should have(1).records
    end

    it "sets the start time as an UTC timestamp" do
      fake_time = Time.at(0)
      Time.stub_chain(:now, :utc).and_return(fake_time)

      AreWeThereYet::Run.new.start(@connection)

      @connection[:runs].all.first[:started_at].should == fake_time
    end

    it "records the id of the run created" do
      run = AreWeThereYet::Run.new
      run.start(@connection)
      run.id.should == @connection[:runs].all.first[:id]
    end
  end

  describe "finish" do
    it "sets the end time as an UTC timestamp" do
      fake_time = Time.at(0)
      Time.stub_chain(:now, :utc).and_return(fake_time)

      run = AreWeThereYet::Run.new
      run.start(@connection)
      run.finish(@connection)

      @connection[:runs].first[:ended_at].should == fake_time
    end
  end
end
