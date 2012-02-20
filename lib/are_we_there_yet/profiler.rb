module AreWeThereYet
  class Profiler
    def initialize(db_location)
      DataMapper.setup(:default, "sqlite://#{db_location}")
    end

    def list_files
      examples = Example.all

      example_averages = examples.map { |ex| { :file => ex.file.to_s, :average_execution_time => ex.average_time } }

      file_averages = example_averages.inject({}) do |output, average_hash|
        output[average_hash[:file]] ||= 0.0
        output[average_hash[:file]] += average_hash[:average_execution_time]
        output
      end

      file_averages_for_sorting = file_averages.inject([]) do |output,file_time|
        output << { :file => file_time.first, :average_execution_time => file_time.last }
        output
      end

      file_averages_for_sorting.sort { |x,y| y[:average_execution_time] <=> x[:average_execution_time] }
    end
  end
end
