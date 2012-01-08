require 'sqlite3'

class AreWeThereYet < Spec::Runner::Formatter::BaseFormatter
  def initialize(options,where)
    @db = SQLite3::Database.new(where)

    existing_tables = @db.execute("SELECT name FROM sqlite_master")

    if existing_tables.empty?
      @db.execute("CREATE TABLE locations(id INTEGER PRIMARY KEY)")
      @db.execute("CREATE TABLE examples(id INTEGER PRIMARY KEY)")
      @db.execute("CREATE TABLE metrics(id INTEGER PRIMARY KEY)")
    end
  end
end
