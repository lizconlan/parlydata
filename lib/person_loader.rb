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
      
      person.forenames = "John" if person.title == "Viscount" and person.surname == "Thurso"
      
      if person.forenames == "Michael" and person.surname == "Foster" and person.born.to_s == "1946-02-26"
        person.forenames = "Michael Jabez"
      end
      
      if person.forenames == "David" and person.surname == "Young" and person.born.to_s == "1928-10-12"
        person.born = "1930-10-12" #some sources say 1928, Who Was Who says 1930 so switching to that
      end
      
      if person.forenames == "Helen" and person.surname == "Brinton"
        person.surname = "Clark"
        person.add_aka("Helen Brinton")
      end
      if person.forenames == "Anne" and person.surname == "Picking"
        person.surname = "Moffat"
        person.add_aka("Ann Picking")
      end
      if person.forenames == "Margaret" and person.surname == "Jackson"
        person.surname = "Beckett"
        person.add_aka("Margaret Jackson")
      end
      if person.forenames == "Margaret" and person.surname == "Bain" and person.born.to_s == "1945-09-01"
        person.add_aka("Margaret Ewing")
        person.add_aka("Margaret McAdam")
      end
      if person.forenames == "John" and person.surname == "Roberts" and person.born.to_s == "1935-10-23"
        person.add_aka("Roger Roberts")
      end
      if person.forenames == "John" and person.surname == "Hannam" and person.born.to_s == "1929-08-02"
        person.add_aka("George Hannam")
      end
      if person.forenames == "Elaine" and person.surname == "Kellett"
        person.add_aka("Elaine Kellett-Bowman")
        person.add_aka("Mary Elaine Kay")
        person.add_aka("Mary Kellett")
        person.add_aka("Dame Mary Elaine Kellett-Bowman")
      end
      
      person.url = record["url"]
      if person.born and person.born.year > 1900 #restrict the dataset to recent times
        born = person.born.year.to_s
        person.id = "#{person.surname}_#{person.forenames[0..0]}_#{born}"
        person.save
      end
    end
  end
  
  def load_from_file(file_name="members.js")
    file = "data/#{file_name}"
    
    data = JSON.parse(File.read(file))
    
    data.each do |record|
      person = Person.new
      person.surname = record["surname"]
      person.forenames = record["forenames"]
      person.title = record["title"] if record["title"]
      person.born = record["born"]
      person.died = record["died"] if record["died"]
      person.id = "#{person.surname}_#{person.forenames[0..0]}_#{person.born.year}"
      person.save
    end
  end
end