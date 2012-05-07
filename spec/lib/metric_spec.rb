require 'spec_helper'

describe AreWeThereYet::Metric do
  before(:each) do
    @db_name = "/tmp/are_we_there_yet_#{Time.now.to_i}_#{rand(100000000)}_spec.sqlite"
    @db = AreWeThereYet::Persistence::Connection.create("sqlite://#{@db_name}")
    AreWeThereYet::Persistence::Schema.create(@db)

    @properties = {:id => 9999, :execution_time => 30.0, :path => '/path/to/file', :run_id => 99, :description => 'blah'}
  end

  after(:each) do
    @db.disconnect
    File.unlink(@db_name) if File.exists? @db_name
  end

  it "is instantiated from a hash of options" do
    m = AreWeThereYet::Metric.new(@properties)
    m.id.should == @properties[:id]
    m.execution_time.should == @properties[:execution_time]
    m.path.should == @properties[:path]
    m.run_id.should == @properties[:run_id]
    m.description.should == @properties[:description]
  end

  it "returns all metrics currently in the provided database" do
    @db[:metrics].insert_multiple([{:path => 'abc'}, {:path => 'def'}])

    all_metrics = AreWeThereYet::Metric.all(@db)
    all_metrics.first.path.should == 'abc'
    all_metrics.last.path.should == 'def'
  end

  it "persists itself to the database" do
    AreWeThereYet::Metric.all(@db).should be_empty
    m = AreWeThereYet::Metric.new(@properties)
    m.save(@db)

    metric = AreWeThereYet::Metric.all(@db).first
    metric.id.should_not == @properties[:id] # even if an id is provided it is not saved - no provision for updates
    metric.execution_time.should  == @properties[:execution_time]
    metric.path.should == @properties[:path]
    metric.description.should == @properties[:description]
    metric.run_id.should == @properties[:run_id]
  end

  it "sets a UTC timestamp in the database to indicate when it was created" do
    fake_created_at = Time.at(0) #use an obviously fake time

    Time.stub_chain(:now, :utc).and_return(fake_created_at)
    m = AreWeThereYet::Metric.new(@properties)
    m.save(@db)

    @db[:metrics].first[:created_at].should == fake_created_at
  end

  it "overwrites any existing id with the id of the record created" do
    m = AreWeThereYet::Metric.new(@properties)
    m.save(@db)

    m.id.should == 1
  end
end
