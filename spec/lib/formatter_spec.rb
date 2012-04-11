require 'spec_helper'

describe AreWeThereYet::Formatter do
  it "returns formatted data for file metrics" do
    input = [
      { :file => "/path/to/spec", :average_execution_time => 32.0 },
      { :file => "/path/to/other/spec", :average_execution_time => 5.0 },
    ]
    output = [
      %Q{"File Path","Average Execution Time"},
      "",
      %Q{"#{input[0][:file]}",#{input[0][:average_execution_time]}},
      %Q{"#{input[1][:file]}",#{input[1][:average_execution_time]}},
    ].join("\n") + "\n"

    AreWeThereYet::Formatter.format_for_output(input).should == output
  end

  it "returns formatted data for exampel metrics" do
    input = [
      { :example => "blaah", :average_execution_time => 20.0 },
      { :example => "blah", :average_execution_time => 12.0 }
    ]
    output = [
      %Q{"Example","Average Execution Time"},
      "",
      %Q{"#{input[0][:example]}",#{input[0][:average_execution_time]}},
      %Q{"#{input[1][:example]}",#{input[1][:average_execution_time]}},
    ].join("\n") + "\n"

    AreWeThereYet::Formatter.format_for_output(input).should == output
  end
end
