require 'rest-client'
require 'json'
require 'date'

require_relative '../models/constituency.rb'

class ConstituencyLoader
  def serialize_name
  end
  
  def load_from_scraperwiki(scraper_name="parly_constituencies")
    url = "https://api.scraperwiki.com/api/1.0/datastore/sqlite?format=jsondict&name=#{scraper_name}&query=select%20*%20from%20%60swdata%60"
    response = RestClient.get(url)
    data = JSON.parse(response.body)
    data.each do |record|
      constituency = Constituency.new
      constituency.name = record["name"]
      constituency.name = "Richmond (Yorks)" if constituency.name == "Richmond" and record["link"] =~ /yorkshire/
      constituency.year_created = record["created"]
      if record["abolished"]
        constituency.year_abolished = record["abolished"]
      end
      constituency.id = "#{constituency.storable_name}_#{constituency.year_created}"
      constituency.save
    end
  end
end