# encoding: utf-8

require 'rest-client'
require 'json'
require_relative '../models/timeline_element.rb'

class SessionLoader
  def load_from_scraperwiki(scraper_name="uk_parliament_sessions")
    url = "https://api.scraperwiki.com/api/1.0/datastore/sqlite?format=jsondict&name=#{scraper_name}&query=select%20*%20from%20%60swdata%60"
    response = RestClient.get(url)
    data = JSON.parse(response.body)
    data.each do |record|
      parly_session = ParliamentarySession.new
      parly_session.start_date = record["begin"]
      parly_session.end_date = record["end"]
      parly_session.reference = record["name"]
      
      parliament = Parliament.where(:start_date.lte => parly_session.start_date.to_time, :end_date.gte => parly_session.end_date.to_time).first
      
      p "#{parly_session.reference}"
      p "#{parliament.id}"
      
      parly_session.parliament_id = parliament.id
      
      parly_session.id = "#{parly_session.reference}_ParliamentarySession"
      parly_session.save
    end
  end
  
  def load_from_file(file_name="members.js")
    file = "data/#{file_name}"
    
    data = JSON.parse(File.read(file))
    
    data.each do |record|
      person = Person.new
      person.surname = record["surname"]
      person.forenames = record["forenames"]
      person.name = "#{record["forenames"]} #{record["surname"]}".squeeze(" ")
      person.title = record["title"] if record["title"]
      person.born = record["born"]
      person.died = record["died"] if record["died"]
      if person.born
        year = person.born.year
      else
        year = "xxxx"
      end
      if record["aka"]
        record["aka"].each do |aka|
          person.add_aka(aka)
        end
      end
      person.add_aka(person.name)
      person.id = "#{person.surname}_#{person.forenames[0..0]}_#{year}".gsub(" ", "_")
      person.save
    end
  end
end