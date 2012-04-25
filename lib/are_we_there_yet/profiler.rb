module AreWeThereYet
  class Profiler
    def initialize(db_connection_string)
      @db = AreWeThereYet::Persistence::Connection.create(db_connection_string)
    end

    def list_files
      sorted_output(average_file_execution_times)
    end

    def list_examples(file_path)
      metrics = Metric.all(@db)

      metrics_by_file = metrics.group_by { |m| m.path }

      if metrics_by_file[file_path]

        metrics_by_example = metrics_by_file[file_path].group_by { |m| m.description }

        metrics_by_example_per_run = metrics_by_example.merge(metrics_by_example) do |example,metrics,metrics|
          metrics.group_by { |m| m.run_id }
        end

        averages_by_example = metrics_by_example_per_run.merge(metrics_by_example_per_run) do |key, runs, runs|
          find_average_time_for runs
        end

        example_averages_for_sorting = averages_by_example.inject([]) do |output, (example, average_execution_time)|
          output << { :example => example, :average_execution_time => average_execution_time }
        end

        sorted_output(example_averages_for_sorting)
      else
        []
      end
    end

    private

    def average_file_execution_times
      metrics = Metric.all(@db)

      metrics_by_file = metrics.group_by { |m| m.path }

      metrics_by_file_per_run = metrics_by_file.merge(metrics_by_file) do |file, metrics, metrics|
        metrics.group_by { |m| m.run_id }
      end

      # The next line is really just a map operation
      averages_by_file = metrics_by_file_per_run.merge(metrics_by_file_per_run) { |key, runs, runs| find_average_time_for runs }

      averages_by_file.inject([]) do |output, (file_path, average_execution_time)|
        output << { :file => file_path, :average_execution_time => average_execution_time }
      end
    end

    def sorted_output(data_to_sort)
      data_to_sort.sort { |x,y| y[:average_execution_time] <=> x[:average_execution_time] }
    end

    def find_average_time_for(runs)
      total_per_run = runs.inject([]) do |memo, (run,metrics)|
        memo << metrics.inject(0.0) { |total,m| total + m.execution_time }
      end

      (total_per_run.inject(:+))/total_per_run.size
    end
  end
end
