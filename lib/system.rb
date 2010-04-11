require 'tempfile'

module System

  def self.db_credentials
    ActiveRecord::Base.connection.instance_eval { @config }
  end

  # Run system commands
  def self.run(command)
    result = system(command)
    raise("error, process exited with status #{$?.exitstatus}") unless result
  end

  # Creates app tar file
  def self.tar_application
    application_tar = Tempfile.new("app")
    cmd = "tar --dereference -czf #{application_tar.path} public/"
    run(cmd)
    return application_tar
  end

  # Creates and runs mysqldump and throws into .tar.gz file.
  # Returns .tar.gz file
  def self.db_dump
    dump_file = Tempfile.new("dump")
    cmd = "mysqldump --quick --single-transaction --create-options #{mysql_options}"
    cmd += " > #{dump_file.path}"
    run(cmd)
    return dump_file
  end

  def self.mysql_options
    cmd = ''
    cmd += " -u #{db_credentials[:username]} " unless db_credentials[:username].nil?
    cmd += " -p'#{db_credentials[:password]}'" unless db_credentials[:password].nil?
    cmd += " -h '#{db_credentials[:host]}'"    unless db_credentials[:host].nil?
    cmd += " #{db_credentials[:database]}"
  end
    
end

