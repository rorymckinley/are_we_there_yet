require 'spec_helper'

describe AreWeThereYet::Metric do
  it "is instantiated from a hash of options" do
    m = AreWeThereYet::Metric.new(:id => 1, :execution_time => 30.0)
    m.id.should == 1
    m.execution_time.should == 30.0
  end
  describe "building from an rspec example" do
    before(:each) do
      @mock_example = mock(Spec::Example::ExampleProxy, :location => "/path/to/spec:42", :description => "blaah")
      @metric = AreWeThereYet::Metric.from_rspec_example(@mock_example, 10.0)
    end

    it "returns an instance of itself" do
      @metric.should be_a AreWeThereYet::Metric
    end

    it "sets the instance's execution time" do
      @metric.execution_time.should == 10.0
    end

    it "sets the example associated with the instance" do
      @metric.example.description.should == @mock_example.description
      @metric.example.file_path.should == @mock_example.location.split(':').first
    end
  end
end
