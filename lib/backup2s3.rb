require 'rubygems'
require 'active_support'
require 'tempfile'
require 'yaml'

class Backup2s3
  include System

  def initialize
    STDOUT.sync = true #used so that print will not buffer output
    ActiveResource::Base.logger = true
    load_backup_manager
    @database_file = ""
    @application_file = ""
    @time = Time.now.utc.strftime("%Y%m%d%H%M%S")
  end


  #CREATE creates a backup
  def create(comment = ENV['comment'])
    create_backup(comment)
    save_backup_manager
  end

  #DELETE deletes a backup
  def delete(backup_id = ENV['id'])
    raise "ID to delete is blank!" and return if backup_id == nil
    delete_backup(backup_id)
    save_backup_manager
  end

  def restore(backup_id = ENV['id'])
    raise "ID to restore is blank!" and return if backup_id == nil
    restore_backup(backup_id)
    save_backup_manager
  end

  #LIST
  def list
    @backup_manager.list_backups
  end


  private

  def create_backup(comment)
    if ApplicationConfig[:database]
      @database_file = "#{@time}-#{System.db_credentials[:database]}-database.sql"
      database_temp = System.db_dump
      puts ""
      puts "- System dump size: " << database_temp.size.to_s << " B"
      print "--- Backing up database..."
      adapter.store(@database_file, open(database_temp.path))
      puts "done"
    end

    if ApplicationConfig[:application].class == Array
      #TODO create selective app dump and move to S3
    elsif ApplicationConfig[:application].class == Symbol and ApplicationConfig[:application] == :full
      @application_file = "#{@time}-#{System.db_credentials[:database]}-application.tar.gz"
      application_temp = System.tar_application
      puts ""
      puts "- Application tarball size: " << application_temp.size.to_s << " B"
      print "--- Backing up application folders..."
      adapter.store(@application_file, open(application_temp.path))
      puts "done"
    end

    if ApplicationConfig[:max_number_of_backups] == @backup_manager.number_of_backups then
      puts ""
      puts "Reached max_number_of_backups, removing oldest backup..."
      backup_to_delete = @backup_manager.get_oldest_backup
      delete_backup(backup_to_delete.time)
    end
    backup = BackupManagement::Backup.new(@time, @application_file, @database_file, comment)
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

  def restore_backup(backup_id)
    backup = @backup_manager.get_backup(backup_id)
    if backup.nil? then
      puts "Backup with ID #{backup_id} does not exist."
      return
    end    

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
