

module Database

  def db_credentials
    ActiveRecord::Base.connection.instance_eval { @config }
  end
    
end
