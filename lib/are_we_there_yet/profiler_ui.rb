module AreWeThereYet
  class ProfilerUI
    def self.get_profiler_output(location, output, options={})
      profiler = Profiler.new(location)
      output.write(Formatter.format_for_output(profiler.list_files))
    end
  end
end
