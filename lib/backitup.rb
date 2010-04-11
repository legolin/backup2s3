require 'rubygems'
require 'active_support'
require 'tempfile'
require 'yaml'

class Backitup
  include Database
  include BackupManagement

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
      @database_file = "#{@time}-#{Database.db_credentials[:database]}-database.sql"
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
      @application_file = "#{@time}-#{Database.db_credentials[:database]}-application.tar.gz"
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
    backup = BackupManagement::Backup.new(@time, @application_file.to_str, @database_file.to_str)
    @backup_manager.add_backup(backup)
    puts ""
  end

  def delete_backup(backup_id)
    backup = @backup_manager.get_backup(backup_id)
    if backup.nil? then
      puts "Backup with ID #{backup_id} does not exist."
      return
    end    
    begin adapter.delete(backup.application_file) rescue puts "Could not delete #{backup.application_file}!" end
    begin adapter.delete(backup.database_file) rescue puts "Could not delete #{backup.database_file}!" end    
    puts (@backup_manager.delete_backup(backup) ?
        "Backup with ID #{backup.time} was successfully deleted." :
        "Warning: Backup with ID #{backup.time} was not found and therefore not deleted.")
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
    cmd += " -u #{Database.db_credentials[:username]} " unless Database.db_credentials[:username].nil?
    cmd += " -p'#{Database.db_credentials[:password]}'" unless Database.db_credentials[:password].nil?
    cmd += " -h '#{Database.db_credentials[:host]}'"    unless Database.db_credentials[:host].nil?
    cmd += " #{Database.db_credentials[:database]}"
  end

  # Returns instance of class used to interface with S3
  def adapter
    return @adapter if @adapter
    selected_adapter = ("Adapters::" << ApplicationConfig[:adapter]).constantize
    @adapter ||= selected_adapter.new(AdapterConfig)
  end  

  def load_backup_manager
    BackupManagement::BackupManager.new()
    BackupManagement::Backup.new(nil, nil, nil)
    begin           
      @backup_manager ||= YAML.load_file(adapter.fetch(BackupManagement::BackupManager.filename).path)
      @backup_manager ||= YAML.load_file(BackupManagement::BackupManager.local_filename)
    rescue
      @backup_manager ||= BackupManagement::BackupManager.new
    end
  end

  def save_backup_manager
    begin
      File.open(BackupManagement::BackupManager.local_filename, "w") { |f| YAML.dump(@backup_manager, f) }
    rescue
      puts "Unable to save local file: " << BackupManagement::BackupManager.local_filename
    end
    begin
      adapter.store(BackupManagement::BackupManager.filename, open(BackupManagement::BackupManager.local_filename))
    rescue
      puts "Unable to save BackupManager to S3"
    end
  end

  

end
