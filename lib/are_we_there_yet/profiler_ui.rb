module AreWeThereYet
  class ProfilerUI
    def self.get_profiler_output(location, options={})
      profiler = Profiler.new(location)
      STDOUT.write(Formatter.format_for_output(profiler.list_files))
    end
  end
end
