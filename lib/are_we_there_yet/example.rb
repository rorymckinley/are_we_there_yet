module AreWeThereYet
  class Example
    include DataMapper::Resource
    storage_names[:default] = "examples"

    property :id, Serial
    property :description, String

    belongs_to :spec_file, :model => "AreWeThereYet::SpecFile"
    has n, :metrics, "AreWeThereYet::Metric"

    def average_time
      metrics.avg(:execution_time)
    end

    def to_s
      description
    end
  end
end
