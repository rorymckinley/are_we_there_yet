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
      @db2.transaction do
        location_id = persist_file(example)

        example_id = persist_example(example, location_id)

        persist_metric(example_id, options.merge(:path => get_file_path_from(example), :description => example.description))
      end
    end

    def close
      @db2[:runs].where(:id => @run_id).update(:ended_at => Time.now.utc) if tracking_runs?
      @db2.disconnect
    end

    private

    def log_run
      @run_id = @db2[:runs].insert(:started_at => Time.now.utc) if tracking_runs?
    end

    def get_file_path_from(example)
      example.location.split(':').first
    end

    def persist_file(example)
      path =  get_file_path_from example

      file = @db2[:spec_files].where(:path => path).first
      if file
        file[:id]
      else
        @db2[:spec_files].insert(:path => path)
      end
    end

    def persist_example(example, spec_file_id)
      persisted_example = @db2[:examples].where[:spec_file_id => spec_file_id, :description => example.description]

      if persisted_example
        persisted_example[:id]
      else
        @db2[:examples].insert(:spec_file_id => spec_file_id, :description => example.description)
      end
    end

    def persist_metric(example_id, options)
      execution_time = options[:execution_time] || Time.now - @start
      path = options[:path]
      description = options[:description]

      metric_data = {
        :example_id => example_id,
        :created_at => Time.now.utc,
        :execution_time => execution_time,
        :path => path,
        :description => description
      }

      metric_data.merge!( :run_id => @run_id ) if tracking_runs?

      @db2[:metrics].insert(metric_data)
    end

    def tracking_runs?
      @db2.tables.include? :runs
    end
  end
end
