require 'rubygems'
require 'active_support'
require 'tempfile'
require 'yaml'



class Backitup
  include Database

  def initialize
    STDOUT.sync = true #used so that print will not buffer output
    ActiveResource::Base.logger = true
    load_backup_manager
    @database_file = ""
    @application_file = ""
    @time = Time.now.utc.strftime("%Y%m%d%H%M%S")
  end


  #CREATE creates a backup
  def create
    create_backup    
    save_backup_manager
  end

  #DELETE deletes a backup
  def delete(backup_id = ENV['ID'])
    raise "ID to delete is blank!" and return if backup_id == nil
    delete_backup(backup_id)
    save_backup_manager
  end

  #LIST
  def list
    @backup_manager.list_backups
  end


  private

  def create_backup
    if ApplicationConfig[:database]
      @database_file = "#{@time}-#{db_credentials[:database]}-database.sql"
      database_temp = db_dump
      puts ""
      puts "- Database dump size: " << database_temp.size.to_s << " B"
      print "--- Backing up database..."
      adapter.store(@database_file, open(database_temp.path))
      puts "done"
    end

    if ApplicationConfig[:application].class == Array
      #TODO create selective app dump and move to S3
    elsif ApplicationConfig[:application].class == Symbol and ApplicationConfig[:application] == :full
      @application_file = "#{@time}-#{db_credentials[:database]}-application.tar.gz"
      application_temp = tar_application
      puts ""
      puts "- Application tarball size: " << application_temp.size.to_s << " B"
      print "--- Backing up application folders..."
      adapter.store(@application_file, open(application_temp.path))
      puts "done"
    end

    if ApplicationConfig[:max_number_of_backups] > @backup_manager.number_of_backups then
      #@backup_manager.remove_oldest_backup
    end
    backup = Backup.new(@time, @application_file, @database_file)
    @backup_manager.add_backup(backup)
  end

  def delete_backup(backup_id)
    backup = @backup_manager.get_backup(backup_id)
    adapter.delete(backup.application_file)
    adapter.delete(backup.database_file)
    @backup_manager.delete_backup(backup)
  end

  # Run system commands
  def run(command)
    result = system(command)
    raise("error, process exited with status #{$?.exitstatus}") unless result
  end
  
  # Creates app tar file
  def tar_application
    application_tar = Tempfile.new("app")
    cmd = "tar --dereference -czf #{application_tar.path} public/"
    run(cmd)    
    return application_tar
  end

  # Creates and runs mysqldump and throws into .tar.gz file.
  # Returns .tar.gz file
  def db_dump
    dump_file = Tempfile.new("dump")
    cmd = "mysqldump --quick --single-transaction --create-options #{mysql_options}"
    cmd += " > #{dump_file.path}"
    run(cmd)    
    return dump_file
  end

  def mysql_options
    cmd = ''
    cmd += " -u #{db_credentials[:username]} " unless db_credentials[:username].nil?
    cmd += " -p'#{db_credentials[:password]}'" unless db_credentials[:password].nil?
    cmd += " -h '#{db_credentials[:host]}'"    unless db_credentials[:host].nil?
    cmd += " #{db_credentials[:database]}"
  end

  # Returns instance of class used to interface with S3
  def adapter
    return @adapter if @adapter
    selected_adapter = ("Adapters::" << ApplicationConfig[:adapter]).constantize
    @adapter ||= selected_adapter.new(AdapterConfig)
  end  

  def load_backup_manager
    begin
      @backup_manager ||= YAML.load_file(adapter.fetch(BackupManager.filename).path)
      @backup_manager ||= (YAML.load_file(BackupManager.local_filename) and puts "Attempting Local Load...")
    rescue
      @backup_manager ||= BackupManager.new
    end
  end

  def save_backup_manager
    begin
      File.open(BackupManager.local_filename, "w") { |f| YAML.dump(@backup_manager, f) }
    rescue
      puts "Unable to save local file: " << BackupManager.local_filename
    end
    begin
      adapter.store(BackupManager.filename, open(BackupManager.local_filename))
    rescue
      puts "Unable to save BackupManager to S3"
    end
  end

  

end
