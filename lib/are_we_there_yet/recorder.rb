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

    def example_passed(example, options={})
      persist_metric(options.merge(:path => get_file_path_from(example), :description => example.description))
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

    def persist_metric(options)
      execution_time = options[:execution_time] || Time.now - @start
      path = options[:path]
      description = options[:description]

      metric_data = {
        :created_at => Time.now.utc,
        :execution_time => execution_time,
        :path => path,
        :description => description
      }

      metric_data.merge!( :run_id => @run_id )

      @db2[:metrics].insert(metric_data)
    end
  end
end
