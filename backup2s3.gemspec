Gem::Specification.new do |s|
  s.summary = "Backup2s3 creates backups of mysql databases and Rails project folders, then uploads them to Amazon S3."
  s.has_rdoc = false
  s.files = ["README", "Rakefile", "CHANGELOG", "generators/backup2s3/backup2s3_generator.rb", "generators/backup2s3/templates/backup2s3.rake", "generators/backup2s3/templates/backup2s3.yml", "generators/backup2s3/USAGE", "init.rb", "lib/backup2s3.rb", "lib/backup2s3/system.rb", "lib/adapters/s3_adapter.rb", "lib/backup_management/backup.rb", "lib/backup_management/backup_manager.rb", "Manifest"]
  s.email = "aric@truespire.com"
  s.version = "0.1"
  s.homepage = "http://github.com/awalker/backup2s3"
  s.name = "backup2s3"
  s.authors = ["Aric Walker"]
end