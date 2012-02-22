module AreWeThereYet
  class Profiler
    def initialize(db_location)
      DataMapper.setup(:default, "sqlite://#{db_location}")
    end

    def list_files
      sort_file_averages average_file_execution_times
    end

    private

    def average_file_execution_times
      example_averages = Example.all.map { |ex| { :file => ex.file.to_s, :average_execution_time => ex.average_time } }

      example_averages.inject({}) do |output, average_hash|
        output[average_hash[:file]] ||= 0.0
        output[average_hash[:file]] += average_hash[:average_execution_time]
        output
      end
    end

    def sort_file_averages(file_averages)
      file_averages_for_sorting = average_file_execution_times.inject([]) do |output,file_time|
        output << { :file => file_time.first, :average_execution_time => file_time.last }
        output
      end

      file_averages_for_sorting.sort { |x,y| y[:average_execution_time] <=> x[:average_execution_time] }
    end
  end
end
