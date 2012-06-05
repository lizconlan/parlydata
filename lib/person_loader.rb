require 'rest-client'
require 'json'
require 'date'
require_relative '../models/person.rb'

class PersonLoader
  def load_from_scraperwiki(scraper_name="parly_people")
    url = "https://api.scraperwiki.com/api/1.0/datastore/sqlite?format=jsondict&name=#{scraper_name}&query=select%20*%20from%20%60swdata%60"
    response = RestClient.get(url)
    data = JSON.parse(response.body)
    data.each do |record|
      person = Person.new
      person.title = record["title"]
      person.forenames = record["forenames"]
      person.surname = record["surname"]
      person.born = record["born"] if record["born"] and record["born"] != ""
      person.died = record["died"] if record["died"] and record["died"] != ""
            
      person.url = record["url"]
      if person.born and person.born.year > 1900 #restrict the dataset to recent times
        born = person.born.year.to_s
        person.id = "#{person.surname}_#{person.forenames[0..0]}_#{born}"
        person.save
      end
    end
  end
end