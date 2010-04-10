namespace :backitup do
  namespace :backup do
    desc "Save a full back to S3"
    task :create => :environment do
      Backitup.new.create_backup
    end

    desc "Save a full back to S3"
    task :delete => :environment do
      Backitup.new.delete_backup
    end

    desc "Save a full back to S3"
    task :list => :environment do
      Backitup.new.list_backups
    end

    desc "Restore your DB from S3"
    task :restore => :environment do
      Backitup.new.restore
    end

#    desc "Keep all backups for the last day, one per day for the last week, and one per week before that. Delete the rest."
#    task :clean => :environment do
#      Backitup.new.clean
#    end
  end

  desc "Show table sizes for your database"
  task :statistics => :environment do
    rows = Backitup.new.statistics
    rows.sort_by {|x| -x[3].to_i }
    header = [["Type", "Data MB", "Index", "Rows", "Name"], []]
    puts (header + rows).collect {|x| x.join("\t") }
  end
end
