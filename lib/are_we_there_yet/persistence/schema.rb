module AreWeThereYet
  module Persistence
    module Schema
      @@tables = {
        :spec_files => Proc.new {
          primary_key :id
          String :path
          index :path
        },
        :runs => Proc.new {
          primary_key :id
          DateTime :started_at
          DateTime :ended_at
        },
        :examples => Proc.new {
          primary_key :id
          Integer :spec_file_id
          column :description, :text
          index [:spec_file_id, :description]
        },
        :metrics => Proc.new {
          primary_key :id
          Integer :example_id
          Float :execution_time
          DateTime :created_at
          Integer :run_id
        }
      }
      def self.create(connection)
        if connection.tables.empty?
          connection.transaction do
            @@tables.each do |name,attributes|
              connection.create_table(name, &attributes)
            end
          end
        end
      end
    end
  end
end
