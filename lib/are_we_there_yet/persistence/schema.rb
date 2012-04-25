module AreWeThereYet
  module Persistence
    module Schema
      @@tables = {
        :runs => Proc.new {
          primary_key :id
          DateTime :started_at
          DateTime :ended_at
        },
        :metrics => Proc.new {
          primary_key :id
          String :path
          column :description, :text
          Float :execution_time
          DateTime :created_at
          Integer :run_id
          index :path
          index :description
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
