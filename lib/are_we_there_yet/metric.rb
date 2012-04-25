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

    def self.all(datastore)
      datastore[:metrics].all.map { |record| new record }
    end
  end
end
