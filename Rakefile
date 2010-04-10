require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('backitup', '0.1.0') do |p|
  p.description = "Backup application and database to S3"
  p.url         = "http://github.com/aricwalker/backitup"
  p.author      = "Aric Walker"
  p.email       = "aric@truespire.com"
  p.ignore_pattern = ["nbproject/*/*", "nbproject/*"]
  p.development_dependencies = []
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each{|ext| load ext }