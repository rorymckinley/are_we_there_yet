module AreWeThereYet
  class Formatter
    def self.format_for_output(data)
      if data.first.has_key? :file
        headers = %Q{"File Path","Average Execution Time"\n\n}
        data.inject(headers) do |output_string, metric_record|
          output_string += %Q{"#{metric_record[:file]}",#{metric_record[:average_execution_time]}\n}
        end
      else
        headers = %Q{"Example","Average Execution Time"\n\n}
        data.inject(headers) do |output_string, metric_record|
          output_string += %Q{"#{metric_record[:example]}",#{metric_record[:average_execution_time]}\n}
        end
      end
    end
  end
end
