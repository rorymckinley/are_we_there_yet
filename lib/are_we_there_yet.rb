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
    @db.transaction do |db|
      location_id = persist_file(db, example)

      example_id = persist_example(db, example, location_id)

      persist_metric(db, example_id)
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
    @db.execute("INSERT INTO runs(id) VALUES(NULL)") if tracking_runs?
    @run_id = @db.last_insert_row_id
  end

  def persist_file(db, example)
    path = example.location.split(':').first

    locations = db.execute("SELECT id FROM files WHERE path = :path", :path => path)
    if locations.empty?
      db.execute("INSERT INTO files(path) VALUES(:path)", :path => path)
      db.last_insert_row_id
    else
      locations.first[0]
    end
  end

  def persist_example(db, example, file_id)
    examples = db.execute(
      "SELECT id FROM examples WHERE file_id = :file_id AND description = :description",
      :file_id => file_id,
      :description => example.description
    )
    if examples.empty?
      db.execute(
        "INSERT INTO examples(file_id, description) VALUES(:file_id, :description)",
        :file_id => file_id,
        :description => example.description
      )
      db.last_insert_row_id
    else
      examples.first[0]
    end
  end

  def persist_metric(db, example_id)
    if tracking_runs?
      db.execute(
        "INSERT INTO metrics(example_id, execution_time, run_id) VALUES(:example_id, :execution_time, :run_id)",
        :example_id => db.last_insert_row_id,
        :execution_time => Time.now - @start,
        :run_id => @run_id
      )
    else
      db.execute(
        "INSERT INTO metrics(example_id, execution_time) VALUES(:example_id, :execution_time)",
        :example_id => db.last_insert_row_id,
        :execution_time => Time.now - @start
      )
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
