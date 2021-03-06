require 'rest-client'
require 'json'
require 'date'
require_relative '../models/person.rb'
require_relative '../models/role_appointment.rb'

class RoleAppointmentsLoader
  def load_from_scraperwiki(scraper_name="uk_prime_ministers")
    url = "https://api.scraperwiki.com/api/1.0/datastore/sqlite?format=jsondict&name=#{scraper_name}&query=select%20*%20from%20%60swdata%60"  
    response = RestClient.get(url)
    data = JSON.parse(response.body)
    data.each do |record|
      if Date.parse(record["pm_from"]) > Date.parse("1978-01-01")
        persons = Person.find_best_matches(record["name"].gsub(/^Sir /, ""))
        
        p ""
        p "looking for #{record["name"]}"
        
        if persons.size > 1
          p "found multiple people :("
        elsif persons.size == 1
          person = persons.first
          p "found #{persons.first.aka[0]}"
        else
          p "#{record["name"]} not found :("
        end
        
        if person
          appointment = RoleAppointment.new()
        
          appointment.title = "Prime Minister"
          appointment.appointed = record["pm_from"]
          appointment.left_role = record["pm_to"] unless record["pm_to"] == "Incumbent"
          appointment.person_id = person.id
        
          appointment.id = "Prime_Minister_#{appointment.appointed.year}-#{appointment.appointed.month}"
          person.role_appointment_ids << appointment.id unless person.role_appointment_ids.include?(appointment.id)
        
          appointment.save
          person.save
        end
        person = nil
      end
    end
  end
end