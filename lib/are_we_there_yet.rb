require 'sqlite3'

class AreWeThereYet < Spec::Runner::Formatter::BaseFormatter
  def initialize(options,where)
    @db = SQLite3::Database.new(where)

    existing_tables = @db.execute("SELECT name FROM sqlite_master")

    if existing_tables.empty?
      @db.execute("CREATE TABLE locations(id INTEGER PRIMARY KEY, path VARCHAR(255))")
      @db.execute("CREATE TABLE examples(id INTEGER PRIMARY KEY, location_id INTEGER, description TEXT)")
      @db.execute("CREATE TABLE metrics(id INTEGER PRIMARY KEY, example_id INTEGER, execution_time FLOAT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)")
    end
  end

  def example_start(example)
    @start = Time.now
  end

  def example_passed(example)
    @db.execute("INSERT INTO locations(path) VALUES(:path)", :path => example.location)
    @db.execute("INSERT INTO examples(location_id, description) VALUES(:location_id, :description)", :location_id => @db.last_insert_row_id, :description => example.description)
    @db.execute("INSERT INTO metrics(example_id, execution_time) VALUES(:example_id, :execution_time)", :example_id => @db.last_insert_row_id, :execution_time => Time.now - @start)
  end
end
