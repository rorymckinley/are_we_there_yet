$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'

#Create an empty class that we will need to inherit from

module Spec
  module Runner
    module Formatter
      class BaseFormatter
      end
    end
  end
end

require 'are_we_there_yet'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  
end

def table_exists?(database_location,table_name)
  SQLite3::Database.new(database_location).execute("SELECT name FROM sqlite_master WHERE name = '#{table_name}'").any?
end
