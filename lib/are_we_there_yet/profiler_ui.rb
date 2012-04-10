module AreWeThereYet
  class ProfilerUI
    class UnknownListingError < StandardError; end
    def self.get_profiler_output(location, output, options={})
      profiler = Profiler.new(location)
      if options[:list] == 'files'
        output.write(Formatter.format_for_output(profiler.list_files))
      elsif options[:list] == 'examples'
        output.write(Formatter.format_for_output(profiler.list_examples(options[:file_path])))
      else
        raise UnknownListingError
      end
    end
  end
end
