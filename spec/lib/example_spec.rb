require 'spec_helper'

describe AreWeThereYet::Example do
  before(:each) do
    @db_name = '/tmp/example_spec_db.sqlite'
    File.unlink(@db_name) if File.exists? @db_name
    DataMapper.setup(:default, "sqlite://#{@db_name}")
  end

  it "averages the time taken across all runs" do
    metric_sets = { :runs => [
      [
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 10 },
        { :location => "/path/to/other/spec", :description => "asdfghij", :execution_time => "5" }
      ],
      [
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 30 },
      ],
      [
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 80.75 },
      ],
    ]}
    MetricFactory.new(@db_name).add_metrics(metric_sets)

    ex = AreWeThereYet::Example.first(:description => "blaah")
    ex.average_time.should == 40.25
  end

  it "uses the example description as the string representation for the class" do
    ex = AreWeThereYet::Example.new
    ex.description = "Something interesting"
    ex.to_s.should == ex.description
  end
end
