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
      per_run_metrics = metrics.inject({}) do |stats, metric|
        stats[metric[:run_id]] ||= {}
        stats[metric[:run_id]][metric[:file]] ||= 0.0
        stats[metric[:run_id]][metric[:file]] += metric[:execution_time]
        stats
      end
      per_file_metrics = per_run_metrics.inject({}) do |stats, run|
        run[1].each do |file, total_time|
          stats[file] ||= { :total_time => 0.0, :number_of_runs => 0.0 }
          stats[file][:total_time] += total_time
          stats[file][:number_of_runs] += 1.0
        end
        stats
      end
      averages = per_file_metrics.inject([]) do |metrics, file_metrics|
        metrics << { :file => file_metrics[0], :average_execution_time => file_metrics[1][:total_time]/file_metrics[1][:number_of_runs] }
      end

      averages.sort { |x,y| y[:average_execution_time] <=> x[:average_execution_time] }
    end
  end
end
