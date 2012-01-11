require "spec/runner/formatter/base_formatter" unless defined? AWTY_SPEC_RUN
require 'sqlite3'
require 'sequel'

class AreWeThereYet < Spec::Runner::Formatter::BaseFormatter
  def initialize(options,where)
    @db = SQLite3::Database.new(where)
    @db2 = Sequel.connect("sqlite://#{where}")

    create_tables

    log_run
  end

  def example_started(example)
    @start = Time.now
  end

  def example_passed(example)
    @db2.transaction do
      location_id = persist_file(example)

      example_id = persist_example(example, location_id)

      persist_metric(example_id)
    end
  end

  def close
    @db.execute(
      "UPDATE runs SET ended_at = :end_time WHERE id = :run_id",
      :end_time => Time.now.utc.strftime("%Y-%m-%d %H:%M:%S"), 
      :run_id => @run_id
    ) if tracking_runs?
    @db.close
  end

  private

  def log_run
    @run_id = @db2[:runs].insert(:started_at => Time.now.utc) if tracking_runs?
  end

  def persist_file(example)
    path = example.location.split(':').first

    file = @db2[:files].where(:path => path).first
    if file
      file[:id]
    else
      @db2[:files].insert(:path => path)
    end
  end

  def persist_example(example, file_id)
    persisted_example = @db2[:examples].where[:file_id => file_id, :description => example.description]
    if persisted_example
      persisted_example[:id]
    else
      @db2[:examples].insert(:file_id => file_id, :description => example.description)
    end
  end

  def persist_metric(example_id)
    execution_time = Time.now - @start
    if tracking_runs?
      @db2[:metrics].insert(:example_id => example_id, :created_at => Time.now, :execution_time => execution_time, :run_id => @run_id)
    else
      @db2[:metrics].insert(:example_id => example_id, :created_at => Time.now, :execution_time => execution_time)
    end
  end
  
  def create_tables
    @db2.transaction do
      if @db2.tables.empty?
        @db2.create_table(:runs) do 
          primary_key :id
          DateTime :started_at
          DateTime :ended_at
        end
        @db2.create_table(:files) do
          primary_key :id
          String :path
          index :path
        end
        @db2.create_table(:examples) do
          primary_key :id
          Integer :file_id
          column :description, :text
          index [:file_id, :description]
        end
        @db2.create_table(:metrics) do
          primary_key :id
          Integer :example_id
          Float :execution_time
          DateTime :created_at
          Integer :run_id
        end
      end
    end
  end

  def tracking_runs?
    @db2.tables.include? :runs
  end
end
