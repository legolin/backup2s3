class Backup2s3Generator < Rails::Generator::Base

  def manifest
    record do |m|
      
      m.directory("lib/tasks")
      m.file("backup2s3.rake", "lib/tasks/backup2s3.rake")

      m.directory("config")
      m.file("backup2s3.yml", "config/backup2s3.yml")

      puts message
    end
  end

  def message
    <<-MESSAGE

    You have successfully installed backup2s3!

    1. Modify your configuration file:

      config/backup2s3.yml

    2.

    
    rake backup2s3:backup:create
    rake backup2s3:backup:delete
    rake backup2s3:backup:list
    rake backup2s3:backup:restore

    # Handy tasks
    rake backup2s3:statistics      # Shows you the size of your DB

    MESSAGE
  end

end