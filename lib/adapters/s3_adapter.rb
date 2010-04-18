require 'aws/s3'
require 'tidy'

class Adapters::S3Adapter

  def initialize(config)
    @config = config
    @connected = false
  end

  def ensure_connected
    return if @connected    
    AWS::S3::Base.establish_connection!(@config)
    AWS::S3::Bucket.create(bucket)
    @connected = true
  end

  def store(file_name, file)
    ensure_connected
    AWS::S3::S3Object.store(file_name, file, bucket)
  end

  def fetch(file_name)
    ensure_connected
    AWS::S3::S3Object.find(file_name, bucket)

    file = Tempfile.new("temp")
    open(file.path, 'w') do |f|
      AWS::S3::S3Object.stream(file_name, bucket) do |chunk|
        f.write chunk
      end
    end
    file
  end

  def read(file_name)
    puts "trying..."
    ensure_connected
    puts "trying..."
    return AWS::S3::S3Object.find(file_name, bucket)
  end

  def list
    ensure_connected
    AWS::S3::Bucket.find(bucket).objects.collect {|x| x.path }
  end

  def delete(file_name)
    if object = AWS::S3::S3Object.find(file_name, bucket)
      object.delete
    end
  end

  private

  def access_key_id

  end

  def bucket    
    @bucket ||= clean("#{ActiveRecord::Base.connection.current_database.to_str.downcase}-ON-#{`hostname`.to_str.downcase}")
  end

  def clean(str)
    str.gsub!(".", "-dot-")
    str.gsub!("_", "-")    
    return str.tidy
  end
end