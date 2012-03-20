module AreWeThereYet
  class Formatter
    def self.format_for_output(data)
      headers = "File Path".ljust(100) + "Average Execution Time".rjust(30) + "\n\n"
      data.inject(headers) do |output_string, metric_record|
        output_string += metric_record[:file].ljust(100) + metric_record[:average_execution_time].to_s.rjust(30) + "\n"
      end
    end
  end
end
