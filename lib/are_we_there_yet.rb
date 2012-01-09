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
      location_id = persist_file(db, example)

      example_id = persist_example(db, example, location_id)

      db.execute(
        "INSERT INTO metrics(example_id, execution_time) VALUES(:example_id, :execution_time)",
        :example_id => db.last_insert_row_id,
        :execution_time => Time.now - @start
      )
    end
  end

  private

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

  def create_tables
    existing_tables = @db.execute("SELECT name FROM sqlite_master")

    if existing_tables.empty?
      @db.transaction do |db|
        db.execute("CREATE TABLE files(id INTEGER PRIMARY KEY, path VARCHAR(255))")
        db.execute("CREATE INDEX path ON files (path)")
        db.execute("CREATE TABLE examples(id INTEGER PRIMARY KEY, file_id INTEGER, description TEXT)")
        db.execute("CREATE INDEX file_description ON examples (file_id, description)")
        db.execute("CREATE TABLE metrics(id INTEGER PRIMARY KEY, example_id INTEGER, execution_time FLOAT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)")
      end
    end
  end
end
