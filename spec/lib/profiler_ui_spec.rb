require 'spec_helper'

describe AreWeThereYet::ProfilerUI do
  before(:each) do
    @db_name = "/tmp/are_we_there_yet_#{Time.now.to_i}_#{rand(100000000)}_spec.sqlite"
  end

  after(:each) do
    File.unlink(@db_name) if File.exists? @db_name
  end

  context "file listing" do
    it "writes a file listing togther with headers to STDOUT" do
      metric_sets = { :runs => [
        [
          { :location => "/path/to/spec", :description => "blaah", :execution_time => 10.0 },
      ]
      ]}
      MetricFactory.new(@db_name).add_metrics(metric_sets)
      path = metric_sets[:runs][0][0][:location]
      time = metric_sets[:runs][0][0][:execution_time]

      output_matcher = /File Path\s+Average Execution Time\n\n#{path}\s+#{time}\n/

      STDOUT.should_receive(:write).with(output_matcher)
      AreWeThereYet::ProfilerUI.get_profiler_output(@db_name, :list => 'files')
    end
  end
end