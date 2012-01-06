require 'sqlite3'

class AreWeThereYet < Spec::Runner::Formatter::BaseFormatter
  def initialize(options,where)
    @db = SQLite3::Database.new(where)
    @db.execute("CREATE TABLE locations(id INTEGER PRIMARY KEY)")
    @db.execute("CREATE TABLE metrics(id INTEGER PRIMARY KEY)")
  end
end
