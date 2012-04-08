module AreWeThereYet
  class SpecFile
    attr_reader :path, :id

    def initialize(options={})
      @db = yield

      @path = options[:path]
      @id = options[:id]
    end

    def to_s
      path
    end

    def self.for_path(path)
      db = yield

      new(db[:spec_files].where(:path => path).first) { db }
    end

    def examples
      @db[:examples].where(:spec_file_id => id).map { |ex_data| AreWeThereYet::Example.new(ex_data) { @db } }
    end

  end
end
