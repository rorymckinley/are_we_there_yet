module AreWeThereYet
  class ProfilerUI
    def self.get_profiler_output(location, output, options={})
      profiler = Profiler.new(location)
      if options[:list] == 'files'
        output.write(Formatter.format_for_output(profiler.list_files))
      else
        output.write(Formatter.format_for_output(profiler.list_examples(options[:file_path])))
      end
    end
  end
end
