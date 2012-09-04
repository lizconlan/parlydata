require 'mongo_mapper'

class LogEntry
  include MongoMapper::Document
  log_url = ENV['LOG_URL'] || YAML::load(File.read("config/mongo.yml"))[:mongolog_url]  || ""
  
  key :ip, String
  key :url, String
  key :params, Array
  key :timestamp, Time
  
  if log_url =~ /mongodb:\/\/([^:]*):([^@]*)@([^:]*):([^\/]*)\/(.*)/
    user = $1
    pass = $2
    address = $3
    port = $4
    db = $5
  end
  
  connection(Mongo::Connection.from_uri(log_url))
  set_database_name(db)
end