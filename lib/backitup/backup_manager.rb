# To change this template, choose Tools | Templates
# and open the template in the editor.

class BackupManager
  include Database
  
  attr_accessor :number_of_backups, :last_backup, :backup_list_filename, :backups


  def initialize
    self.backups = Array.new
  end

  def self.filename
    "#{db_credentials[:database]}_#{`hostname`.tidy}_backups.yaml".tidy
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
  end

  def get_backup(backup_id)
    self.backups.each { |backup|
        if backup.time == backup_id then
          return backup
        end
    }
  end

  def list_backups(details = ENV['details'])
    backups = self.backups.sort {|a,b| b[:time] <=> a[:time]}
    puts "--- Backups by Date ---"
    count = 1
    for backup in backups do
      backup_date = DateTime.parse(backup.time)
      puts "#{count}. #{backup.human_readable_time}, ID - #{backup.time}"
      if details then
        puts "   --- App -> #{backup.application_file}"
        puts "   --- DB -> #{backup.database_file}"
      end
      count = count.next
    end
    puts "-----------------------"
  end

  def delete_backup(backup_id = ENV['ID'])
    if backup_id.is_a?(String)
      
      adapter.delete
    else
      puts "Invalid parameter passed. Delete unsuccessful"
    end
  end    
  
end
