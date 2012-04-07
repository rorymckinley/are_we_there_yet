module AreWeThereYet
  class SpecFile
    include DataMapper::Resource
    storage_names[:default] = "spec_files"

    property :id, Serial
    property :path, String

    has n, :examples, "AreWeThereYet::Example"

    def to_s
      path
    end

    def self.for_path(path)
      first(:path => path)
    end
  end
end
