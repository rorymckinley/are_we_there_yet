require 'sequel'

module AreWeThereYet
  class Profiler
    def initialize(db_location)
      @db = Sequel.connect("sqlite://#{db_location}")
    end

    def list_files
      execution_times = @db[:files].join(:examples, :file_id => :id).join(:metrics, :example_id => :id)
      [{ :file => execution_times.first[:path], :execution_time => execution_times.first[:execution_time] }]
    end
  end
end
