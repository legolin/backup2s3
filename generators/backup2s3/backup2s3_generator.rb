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

    -------------------------------------------------------------------

    You have successfully installed backup2s3!

    1. Modify your configuration file:

      config/backup2s3.yml

    2. Get started.

      Backup tasks
      
        rake backup2s3:backup:create  - Creates a backup and moves it to S3
        rake backup2s3:backup:delete  - Deletes the specific backup
        rake backup2s3:backup:list    - Lists all backups that are currently on S3
        rake backup2s3:backup:restore - Restores a specific backup

      Some handy tasks
        rake backup2s3:statistics     - Shows you the size of your DB

    -------------------------------------------------------------------

    MESSAGE
  end

end