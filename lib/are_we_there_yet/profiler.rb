module AreWeThereYet
  class Profiler
    def initialize(db_connection_string)
      @db = AreWeThereYet::Persistence::Connection.create(db_connection_string)
    end

    def list_files
      averages_by_file = get_average_per_key(metrics_by_file)

      sorted_output(transform_averages_for_sorting(averages_by_file, :file))
    end

    def list_examples(file_path)
      if metrics_by_file[file_path]
        metrics_by_example = metrics_by_file[file_path].group_by { |m| m.description }

        averages_by_example = get_average_per_key(metrics_by_example)

        sorted_output(transform_averages_for_sorting(averages_by_example, :example))
      else
        []
      end
    end

    private

    def sorted_output(data_to_sort)
      data_to_sort.sort { |x,y| y[:average_execution_time] <=> x[:average_execution_time] }
    end

    def find_average_time_for(runs)
      total_per_run = runs.inject([]) do |memo, (run,metrics)|
        memo << metrics.inject(0.0) { |total,m| total + m.execution_time }
      end

      (total_per_run.inject(:+))/total_per_run.size
    end

    def metrics_by_file
      @metrics_by_file || Metric.all(@db).group_by { |m| m.path }
    end

    def get_average_per_key(metric_set)
      # Merging a hash with itself is really just a sneaky way to do a map
      metrics_by_key_per_run = metric_set.merge(metric_set) do |key, metrics, ignore_this|
        metrics.group_by { |m| m.run_id }
      end

      averages_by_key = metrics_by_key_per_run.merge(metrics_by_key_per_run) do |key, runs, ignore_this|
        find_average_time_for runs
      end
    end

    def transform_averages_for_sorting(averages_by_key, key_name)
      averages_by_key.map do |key, average_execution_time|
        { key_name.to_sym => key, :average_execution_time => average_execution_time }
      end
    end
  end
end
