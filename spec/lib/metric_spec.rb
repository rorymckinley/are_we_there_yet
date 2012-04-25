require 'spec_helper'

describe AreWeThereYet::Metric do
  it "is instantiated from a hash of options" do
    m = AreWeThereYet::Metric.new(:id => 1, :execution_time => 30.0, :path => '/path/to/file', :run_id => 99, :description => 'blah')
    m.id.should == 1
    m.execution_time.should == 30.0
    m.path.should == '/path/to/file'
    m.run_id.should == 99
    m.description.should == 'blah'
  end

  it "can return all metrics currently in the provided data store" do
    @db_name = "/tmp/are_we_there_yet_#{Time.now.to_i}_#{rand(100000000)}_spec.sqlite"
    @db = AreWeThereYet::Persistence::Connection.create("sqlite://#{@db_name}")
    AreWeThereYet::Persistence::Schema.create(@db)

    @db[:metrics].insert_multiple([{:path => 'abc'}, {:path => 'def'}])

    all_metrics = AreWeThereYet::Metric.all(@db)
    all_metrics.first.path.should == 'abc'
    all_metrics.last.path.should == 'def'
  end
end
