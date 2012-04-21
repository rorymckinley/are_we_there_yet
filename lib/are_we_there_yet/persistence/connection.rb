module AreWeThereYet
  module Persistence
    module Connection
      class InvalidDBLocation < StandardError; end
      def self.create(uri)
        Sequel.connect(uri)
      rescue
        raise AreWeThereYet::Persistence::Connection::InvalidDBLocation,
          "Could not connect to the database specified by the URI - please check that the location is valid"
      end
    end
  end
end
