require 'rest-client'
require 'json'
require 'date'
require_relative '../models/constituency.rb'

class ConstituencyLoader
  #shouldn't be here - sloppy
  MONGO_URL = ENV['MONGOHQ_URL'] || YAML::load(File.read("config/mongo.yml"))[:mongohq_url]
  
  def initialize
    env = {}
    MongoMapper.config = { env => {'uri' => MONGO_URL} }
    MongoMapper.connect(env)
  end
    
  def load_from_scraperwiki(scraper_name="parly_constituencies")
    url = "https://api.scraperwiki.com/api/1.0/datastore/sqlite?format=jsondict&name=#{scraper_name}&query=select%20*%20from%20%60swdata%60"
    response = RestClient.get(url)
    data = JSON.parse(response.body)
    data.each do |record|
      constituency = Constituency.new
      constituency.name = record["name"]
      constituency.year_created = record["created"]
      if record["abolished"]
        constituency.year_abolished = record["abolished"]
      end
      constituency.id = "#{constituency.name}_#{constituency.year_created}"
      constituency.save
    end
  end
end