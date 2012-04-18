module AreWeThereYet
  module Persistence
    module Schema
      def self.create(connection)
        if connection.tables.empty?
          connection.transaction do
            connection.create_table(:spec_files) do
              primary_key :id
              String :path
              index :path
            end
            connection.create_table(:runs) do
              primary_key :id
              DateTime :started_at
              DateTime :ended_at
            end
            connection.create_table(:examples) do
              primary_key :id
              Integer :spec_file_id
              column :description, :text
              index [:spec_file_id, :description]
            end
            connection.create_table(:metrics) do
              primary_key :id
              Integer :example_id
              Float :execution_time
              DateTime :created_at
              Integer :run_id
            end
          end
        end
      end
    end
  end
end
