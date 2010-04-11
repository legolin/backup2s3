namespace :backup2s3 do
  namespace :backup do
    desc "Save a full back to S3"
    task :create => :environment do
      Backup2s3.new.create
    end

    desc "Save a full back to S3"
    task :delete => :environment do
      Backup2s3.new.delete
    end

    desc "Save a full back to S3"
    task :list => :environment do
      Backup2s3.new.list
    end

    desc "Restore your DB from S3"
    task :restore => :environment do
      Backup2s3.new.restore
    end

#    desc "Keep all backups for the last day, one per day for the last week, and one per week before that. Delete the rest."
#    task :clean => :environment do
#      Backup2s3.new.clean
#    end
  end

  desc "Show table sizes for your database"
  task :statistics => :environment do
    rows = Backup2s3.new.statistics
    rows.sort_by {|x| -x[3].to_i }
    header = [["Type", "Data MB", "Index", "Rows", "Name"], []]
    puts (header + rows).collect {|x| x.join("\t") }
  end
end
