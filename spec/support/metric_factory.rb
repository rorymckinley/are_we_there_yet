class MetricFactory
  def initialize(db_name)
    @db_name = db_name
  end

  def add_metrics(metrics)
    metrics[:runs].each do |run|
      store_run(run)
    end
  end

  private

  def store_run(run)
    recorder = AreWeThereYet::Recorder.new({}, @db_name)
    run.each do |metric_set|
      example = Spec::Example::ExampleProxy.new(metric_set[:description], metric_set[:location])
      recorder.example_passed(example, :execution_time => metric_set[:execution_time])
    end
    recorder.close
  end
end