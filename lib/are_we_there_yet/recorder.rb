module AreWeThereYet
  class Recorder < Spec::Runner::Formatter::BaseFormatter
    def initialize(options,where)
      @db2 = AreWeThereYet::Persistence::Connection.create(where)

      AreWeThereYet::Persistence::Schema.create(@db2)

      log_run
    end

    def example_started(example)
      @start = Time.now
    end

    def example_passed(example)
      persist_metric(example)
    end

    def close
      @db2[:runs].where(:id => @run_id).update(:ended_at => Time.now.utc)
      @db2.disconnect
    end

    private

    def log_run
      @run_id = @db2[:runs].insert(:started_at => Time.now.utc)
    end

    def get_file_path_from(example)
      example.location.split(':').first
    end

    def persist_metric(example)

      metric = AreWeThereYet::Metric.new(
        :execution_time => Time.now - @start,
        :path => get_file_path_from(example),
        :description => example.description,
        :run_id => @run_id
      )

      metric.save(@db2)
    end
  end
end
