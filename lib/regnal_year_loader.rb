require 'rest-client'
require 'json'
require 'date'
require_relative '../models/timeline_element.rb'

class RegnalYearLoader
  #shouldn't be here - sloppy
  MONGO_URL = ENV['MONGOHQ_URL'] || YAML::load(File.read("config/mongo.yml"))[:mongohq_url]
  
  def initialize
    env = {}
    MongoMapper.config = { env => {'uri' => MONGO_URL} }
    MongoMapper.connect(env)
  end
    
  def load_from_scraperwiki(scraper_name="regnal_years")
    url = "https://api.scraperwiki.com/api/1.0/datastore/sqlite?format=jsondict&name=#{scraper_name}&query=select%20*%20from%20%60swdata%60"
    response = RestClient.get(url)
    data = JSON.parse(response.body)
    data.each do |record|
      regnal = RegnalYear.new
      regnal.start_date = record["year_start"]
      regnal.end_date = record["year_end"]
      regnal.abbreviation = record["abbreviation"]
      regnal.monarch = record["monarch"]
      regnal.year_of_reign = record["year"].to_i
      regnal.save
    end
  end
end