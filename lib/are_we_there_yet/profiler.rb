require 'sequel'

module AreWeThereYet
  class Profiler
    def initialize(db_location)
      @db = Sequel.connect("sqlite://#{db_location}")
    end

    def list_files
      metrics = @db[:files].join(:examples, :file_id => :id).join(:metrics, :example_id => :id).map do |row| 
        { :file => row[:path], :execution_time => row[:execution_time], :run_id => row[:run_id] }
      end 
      aggregated_metrics = metrics.inject({}) do |stats, metric|
        stats[metric[:run_id]] ||= {}
        stats[metric[:run_id]][metric[:file]] ||= { :total_execution_time => 0.0 }
        stats[metric[:run_id]][metric[:file]][:total_execution_time] += metric[:execution_time]
      end
    end
  end
end
