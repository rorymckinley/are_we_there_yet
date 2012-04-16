require 'spec_helper'

describe AreWeThereYet::SpecFile do
  before(:each) do
    @db_name = "/tmp/are_we_there_yet_#{Time.now.to_i}_#{rand(100000000)}_spec.sqlite"
    @db = "sqlite://#{@db_name}"
    @connection = Sequel.connect(@db)

    metric_sets = { :runs => [
      [
        { :location => "/path/to/spec", :description => "blaah", :execution_time => 10 },
        { :location => "/path/to/spec", :description => "blaah_some_more", :execution_time => 5 },
        { :location => "/path/to/other/spec", :description => "asdfghij", :execution_time => "5" }
      ],
    ]}
    MetricFactory.new(@db).add_metrics(metric_sets)

    @f = AreWeThereYet::SpecFile.for_path("/path/to/spec") { @connection }
  end

  after(:each) do
    File.unlink(@db_name) if File.exists? @db_name
  end

  it "assigns the path and id passed to it when initialised" do
    f = AreWeThereYet::SpecFile.new(:id => 999, :path => '/bl/ah') { @connection }
    f.path.should == '/bl/ah'
    f.id.should == 999
  end

  it "initialiases with nil values for path and id if a hash of options is not provided" do
    f = AreWeThereYet::SpecFile.new(nil) { @connection }
    f.path.should be_nil
    f.id.should be_nil
  end

  it "exposes the id generated for the file" do
    @f.id.should == 1
  end

  it "uses the file path as the string representation of a file" do
    @f.to_s.should eq @f.path
  end

  it "retrieves an instance of itself based on the file path" do
    @f.path.should eql "/path/to/spec"
  end

  it "maintains a collection of all its associated examples" do
    @f.examples.size.should == 2
    (@f.examples.all? { |ex| ["blaah", "blaah_some_more"].include? ex.description }).should be_true
  end
end
