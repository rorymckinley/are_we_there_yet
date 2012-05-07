module AreWeThereYet
  class Metric
    attr_reader :id, :execution_time, :path, :run_id, :description
    def initialize(options={})
      @id = options[:id]
      @execution_time = options[:execution_time]
      @path = options[:path]
      @run_id = options[:run_id]
      @description = options[:description]
    end

    # Only works for creates not for updates - will need to be cleverer if we ever need to provide for updates
    def save(datastore)
      @id = datastore[:metrics].insert(to_h.merge(:created_at => Time.now.utc))
    end

    def self.all(datastore)
      datastore[:metrics].all.map { |record| new record }
    end

    private

    def to_h
      { :execution_time => execution_time, :path => path, :description => description, :run_id => run_id }
    end
  end
end
