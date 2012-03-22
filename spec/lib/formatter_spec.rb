require 'spec_helper'

describe AreWeThereYet::Formatter do
  it "returns formatted data for file metrics" do
    input = [
      { :file => "/path/to/spec", :average_execution_time => 32.0 },
      { :file => "/path/to/other/spec", :average_execution_time => 5.0 },
    ]
    output = [
      "File Path".ljust(100) + "Average Execution Time".rjust(30),
      "",
      input[0][:file].ljust(100) + input[0][:average_execution_time].to_s.rjust(30),
      input[1][:file].ljust(100) + input[1][:average_execution_time].to_s.rjust(30),
    ].join("\n") + "\n"

    AreWeThereYet::Formatter.format_for_output(input).should == output
  end

  it "returns formatted data for exampel metrics" do
    input = [
      { :example => "blaah", :average_execution_time => 20.0 },
      { :example => "blah", :average_execution_time => 12.0 }
    ]
    output = [
      "Example".ljust(100) + "Average Execution Time".rjust(30),
      "",
      input[0][:example].ljust(100) + input[0][:average_execution_time].to_s.rjust(30),
      input[1][:example].ljust(100) + input[1][:average_execution_time].to_s.rjust(30),
    ].join("\n") + "\n"

    AreWeThereYet::Formatter.format_for_output(input).should == output
  end
end
