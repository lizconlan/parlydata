require 'mongo_mapper'

require_relative "log_entry"

class SimpleLogger
  def self.initialize
    log_url = ENV['LOG_URL'] || YAML::load(File.read("config/mongo.yml"))[:mongolog_url]
    env = {}
    MongoMapper.config = { env => {'uri' => log_url} }
    MongoMapper.connect(env)
  end
  
  def log(req)
    log_entry = LogEntry.new()
    log_entry.url = req.env["REQUEST_PATH"]
    log_entry.params = req.env["QUERY_STRING"].split("&")
    if req.env["HTTP_X_FORWARDED_FOR"]
      log_entry.ip = req.env["HTTP_X_FORWARDED_FOR"]
    else
      log_entry.ip = req.env["REMOTE_ADDR"]
    end
    log_entry.timestamp = Time.now
    log_entry.save
  end
end