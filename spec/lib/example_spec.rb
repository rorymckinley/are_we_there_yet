require 'spec_helper'

describe AreWeThereYet::Example do
  before(:each) do
    @db_name = "/tmp/are_we_there_yet_#{Time.now.to_i}_#{rand(100000000)}_spec.sqlite"
    @db = Sequel.connect("sqlite://#{@db_name}")
  end

  after(:each) do
    File.unlink(@db_name) if File.exists? @db_name
  end

  it "is instantiated from a hash containing the necessary data elements" do
    ex = AreWeThereYet::Example.new(:description => 'test', :spec_file_id => 1, :id => 11) { @db }
    ex.description.should eql 'test'
    ex.spec_file_id.should eql 1
    ex.id.should eql 11
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

    ex = AreWeThereYet::Example.new(@db[:examples].where(:description => "blaah").first) { @db }
    ex.average_time.should == 40.25
  end

  it "provides a method to return all instances" do
    metric_sets = { :runs => [
      [
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 10 },
        { :location => "/path/to/other/spec", :description => "asdfghij", :execution_time => "5" }
      ],
    ]}
    MetricFactory.new(@db_name).add_metrics(metric_sets)

    examples = AreWeThereYet::Example.all { @db }
    examples.size.should == 2
    examples.first.should respond_to :description
  end

  it "uses the example description as the string representation for the class" do
    ex = AreWeThereYet::Example.new(:description => 'Something interesting') { @db }
    ex.to_s.should == 'Something interesting'
  end

  it "returns the file associated with the example" do
    metric_sets = { :runs => [
      [
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 10 },
      ],
    ]}
    MetricFactory.new(@db_name).add_metrics(metric_sets)

    ex = AreWeThereYet::Example.new(@db[:examples].first) { @db }
    ex.spec_file.path.should == "/path/to/spec"
  end
end
