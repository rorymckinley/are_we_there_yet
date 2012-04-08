module AreWeThereYet
  class Profiler
    def initialize(db_location)
      DataMapper.setup(:default, "sqlite://#{db_location}")
      @db = Sequel.connect("sqlite://#{db_location}")
    end

    def list_files
      sorted_output(average_file_execution_times)
    end

    def list_examples(file_path)
      file = SpecFile.for_path(file_path) { @db }
      example_averages_for_sorting = file.examples.map { |ex| { :example => ex.to_s, :average_execution_time => ex.average_time } }

      sorted_output(example_averages_for_sorting)
    end

    private

    def average_file_execution_times
      all_examples = Example.all { @db }
      example_averages = all_examples.map { |ex| { :file => ex.spec_file.to_s, :average_execution_time => ex.average_time } }

      av_by_file = example_averages.inject({}) do |output, average_hash|
        output[average_hash[:file]] ||= 0.0
        output[average_hash[:file]] += average_hash[:average_execution_time]
        output
      end

      file_averages_for_sorting = av_by_file.inject([]) do |output,file_time|
        output << { :file => file_time.first, :average_execution_time => file_time.last }
        output
      end

      file_averages_for_sorting
    end

    def sorted_output(data_to_sort)
      data_to_sort.sort { |x,y| y[:average_execution_time] <=> x[:average_execution_time] }
    end
  end
end
