require 'spec_helper'

describe AreWeThereYet::Metric do
  it "is instantiated from a hash of options" do
    m = AreWeThereYet::Metric.new(:id => 1, :execution_time => 30.0)
    m.id.should == 1
    m.execution_time.should == 30.0
  end
end
