module AreWeThereYet
  class Run
    attr_reader :id
    def start(database)
      @id = database[:runs].insert(:started_at => Time.now.utc)
    end

    def finish(database)
      database[:runs].where(:id => id).update(:ended_at => Time.now.utc)
    end
  end
end
