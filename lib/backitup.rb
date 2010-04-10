require 'rubygems'
require 'active_support'
require 'tempfile'
require 'yaml'



class Backitup

  def initialize
    STDOUT.sync = true #used so that print will not buffer output
    ActiveResource::Base.logger = true
    backup_list
    @database_file = ""
    @application_file = ""
    @current_time = Time.now.utc.strftime("%Y%m%d%H%M%S")
  end

  def create_backup

    #Creates .sql of database dump and stores it on S3
    if ApplicationConfig[:database]      
      @database_file = "#{@current_time}-#{db_credentials[:database]}-database.sql"
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
      @application_file = "#{@current_time}-#{db_credentials[:database]}-application.tar.gz"
      application_temp = tar_application
      puts ""
      puts "- Application tarball size: " << application_temp.size.to_s << " B"
      print "--- Backing up application folders..."
      adapter.store(@application_file, open(application_temp.path))
      puts "done"      
    end

    add_backup_info_to_list

    save_backup_info   

  end

  def delete_backup(backup)
    if backup.is_a?(String)

    elsif backup.is_a?(Array)

    else
      puts "Invalid parameter passed. Delete unsuccessful"
    end
  end


  def list_backups
    backups = backup_list[:backups].sort {|a,b| b[:time] <=> a[:time]}
    puts "--- Backups by Date ---"
    count = 1
    for backup in backups do
      backup_date = DateTime.parse(backup[:time])
      puts "#{count}. #{backup_date.strftime("%m-%d-%Y %H:%M:%S")} | App - #{backup[:application_file]}, DB - #{backup[:database_file]}"
      count = count.next
    end
    puts "-----------------------"
  end


  private

  # Run system commands
  def run(command)
    result = system(command)
    raise("error, process exited with status #{$?.exitstatus}") unless result
  end

  # Creates
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

  def db_credentials
    ActiveRecord::Base.connection.instance_eval { @config }
  end






  #---------BACKUP LIST MANAGEMENT METHODS---------
  def backup_list_filename
    @backup_list_filename ||= "#{db_credentials[:database]}_#{`hostname`.tidy}_backups.yaml".tidy
  end

  def backup_list
    begin
      @backup_list ||= YAML.load_file(adapter.fetch(backup_list_filename).path)
      @backup_list ||= YAML.load_file(local_backup_list)
    rescue
      @backup_list ||= new_backup_list
    end
  end

  def add_backup_info_to_list
    if backup_list[:application_info][:number_of_backups] > ApplicationConfig[:max_number_of_backups] then
      #remove_oldest_backup
    end
    backup_list[:backups] << new_backup_instance
  end

  def save_backup_info
    begin
      File.open(local_backup_list, "w") { |f| YAML.dump(backup_list, f) }
    rescue
      puts "Unable to save file: " << local_backup_list
    end
    adapter.store(backup_list_filename, open(local_backup_list))
  end

  def local_backup_list
    "#{RAILS_ROOT}/lib/#{backup_list_filename}"
  end

  def new_backup_list
    {
      :application_info => {
        :number_of_backups => 0,
        :last_backup => ""
      },
      
      :backups => []
    }
  end

  def new_backup_instance
    {
      :time => @current_time,
      :database_file => @database_file,
      :application_file => @application_file
    }
  end


end
