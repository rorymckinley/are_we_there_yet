module AreWeThereYet
  class File
    include DataMapper::Resource
    storage_names[:default] = "files"

    property :id, Serial
    property :path, String

    def to_s
      path
    end
  end
end
