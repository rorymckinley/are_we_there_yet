require "spec/runner/formatter/base_formatter" unless defined? AWTY_SPEC_RUN
require 'sqlite3'

class AreWeThereYet < Spec::Runner::Formatter::BaseFormatter
  def initialize(options,where)
    @db = SQLite3::Database.new(where)

    create_tables
  end

  def example_started(example)
    @start = Time.now
  end

  def example_passed(example)
    @db.transaction do |db|
      location_id = persist_location(db, example)

      example_id = persist_example(db, example, location_id)

      db.execute(
        "INSERT INTO metrics(example_id, execution_time) VALUES(:example_id, :execution_time)",
        :example_id => db.last_insert_row_id,
        :execution_time => Time.now - @start
      )
    end
  end

  private

  def persist_location(db, example)
    path = example.location.split(':').first

    locations = db.execute("SELECT id FROM locations WHERE path = :path", :path => path)
    if locations.empty?
      db.execute("INSERT INTO locations(path) VALUES(:path)", :path => path)
      db.last_insert_row_id
    else
      locations.first[0]
    end
  end

  def persist_example(db, example, location_id)
    examples = db.execute(
      "SELECT id FROM examples WHERE location_id = :location_id AND description = :description",
      :location_id => location_id,
      :description => example.description
    )
    if examples.empty?
      db.execute(
        "INSERT INTO examples(location_id, description) VALUES(:location_id, :description)",
        :location_id => location_id,
        :description => example.description
      )
      db.last_insert_row_id
    else
      examples.first[0]
    end
  end

  def create_tables
    existing_tables = @db.execute("SELECT name FROM sqlite_master")

    if existing_tables.empty?
      @db.transaction do |db|
        db.execute("CREATE TABLE locations(id INTEGER PRIMARY KEY, path VARCHAR(255))")
        db.execute("CREATE INDEX path ON locations (path)")
        db.execute("CREATE TABLE examples(id INTEGER PRIMARY KEY, location_id INTEGER, description TEXT)")
        db.execute("CREATE INDEX location_description ON examples (location_id, description)")
        db.execute("CREATE TABLE metrics(id INTEGER PRIMARY KEY, example_id INTEGER, execution_time FLOAT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)")
      end
    end
  end
end
