require 'yaml'

class BackupManagement::BackupManager
  include Database
  
  attr_accessor :backup_list_filename, :backups


  def initialize    
    self.backups = Array.new
  end

  def self.filename
    "#{Database.db_credentials[:database]}_#{`hostname`.tidy}_backups.yaml".tidy
  end

  def self.local_filename
    "#{RAILS_ROOT}/lib/#{filename}"
  end

  def add_backup(backup)
    self.backups << backup
  end

  def delete_backup(backup)
    self.backups.delete(backup)
  end

  def delete_backup_by_id(backup_id)
    self.backups.each { |backup|
      if backup.time == backup_id then
        self.backups.delete(backup)
      end
    }
    nil
  end

  def get_backup(backup_id)
    self.backups.each { |backup|
      if backup.time == backup_id then
        return backup
      end
    }
    nil
  end

  def list_backups(details = ENV['details'])
    puts "--- Backups by Date ---"
    count = 1
    self.backups.sort{|a,b| b.time <=> a.time}.each do |backup|
      puts "#{count}. #{backup.human_readable_time}, ID - #{backup.time}"
      if details then
        puts "   --- App -> #{backup.application_file}"
        puts "   --- DB -> #{backup.database_file}"
      end
      count = count.next
    end
    puts "-----------------------"
  end  

  def number_of_backups
    backups.size
  end
  
end
