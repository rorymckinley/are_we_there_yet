module AreWeThereYet
  class Metric
    attr_reader :id, :execution_time
    def initialize(options={})
      @id = options[:id]
      @execution_time = options[:execution_time]
    end
  end
end
