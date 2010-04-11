# To change this template, choose Tools | Templates
# and open the template in the editor.

class Backup

  attr_accessor :time, :application_file, :database_file
  
  def initialize(time, application_file, database_file)
    self.time = time
    self.application_file = application_file
    self.database_file = database_file
  end

  def human_readable_time
    self.time.strftime("%m-%d-%Y %H:%M:%S")
  end
end
