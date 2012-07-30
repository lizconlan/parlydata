require 'rest-client'
require 'json'
require 'date'
require_relative '../models/timeline_element.rb'

class ParliamentLoader
  def load_from_file(file_name="parliaments.js")
    file = "data/#{file_name}"
    data = JSON.parse(File.read(file))
    data.each do |record|
      parliament = Parliament.new
      parliament.start_date = record["start_date"]
      parliament.end_date = record["end_date"]
      parliament.number = record["number"]
      parliament.id = "#{parliament.number}_Parliament"
      parliament.save
    end
  end
end