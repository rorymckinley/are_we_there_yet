module AreWeThereYet
  class Recorder < Spec::Runner::Formatter::BaseFormatter
    def initialize(options,where)
      @db = AreWeThereYet::Persistence::Connection.create(where)

      AreWeThereYet::Persistence::Schema.create(@db)

      log_run
    end

    def example_started(example)
      @start = Time.now
    end

    def example_passed(example)
      persist_metric(example)
    end

    def close
      @run.finish(@db)
      @db.disconnect
    end

    private

    def log_run
      @run = AreWeThereYet::Run.new
      @run.start(@db)
    end

    def get_file_path_from(example)
      example.location.split(':').first
    end

    def persist_metric(example)

      metric = AreWeThereYet::Metric.new(
        :execution_time => Time.now - @start,
        :path => get_file_path_from(example),
        :description => example.description,
        :run_id => @run.id
      )

      metric.save(@db)
    end
  end
end
