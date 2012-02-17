module AreWeThereYet
  class Metric
    include DataMapper::Resource
    storage_names[:default] = "metrics"

    property :id, Serial
    property :execution_time, Float
  end
end
