

  module Database

    def self.db_credentials
      ActiveRecord::Base.connection.instance_eval { @config }
    end
    
  end

