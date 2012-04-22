module AreWeThereYet
  class Metric
    attr_reader :id, :execution_time
    attr_accessor :example

    def self.from_rspec_example(example, execution_time)
      metric = new(:execution_time => execution_time)
      metric.example = AreWeThereYet::Example.new(:description => example.description)
      metric
    end

    def initialize(options={})
      @id = options[:id]
      @execution_time = options[:execution_time]
    end
  end
end
