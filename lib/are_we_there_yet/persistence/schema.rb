module AreWeThereYet
  module Persistence
    module Schema
      def self.create(connection)
        connection.create_table(:spec_files) do
          primary_key :id
          DateTime :started_at
        end
      end
    end
  end
end
