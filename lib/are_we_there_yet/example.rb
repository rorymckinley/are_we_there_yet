module AreWeThereYet
  class Example
    attr_reader :id, :spec_file_id, :description

    def initialize(options)
      @db = yield if_block_provided?

      @id = options[:id]
      @spec_file_id = options[:spec_file_id]
      @description = options[:description]
    end

    def average_time
      (metrics.inject(0.0) { |memo,metric| memo += metric.execution_time })/metrics.length
    end

    def to_s
      description
    end

    def spec_file
      AreWeThereYet::SpecFile.new(@db[:spec_files].where(:id => @spec_file_id).first) { @db }
    end

    def self.all
      db = yield

      db[:examples].all.map { |example_data| new(example_data) { db } }
    end
    private

    def metrics
      @db[:metrics].where(:example_id => id).map { |metric_data| AreWeThereYet::Metric.new(metric_data) }
    end
  end
end
