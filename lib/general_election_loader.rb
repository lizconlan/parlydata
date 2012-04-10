require 'rest-client'
require 'json'
require 'date'
require_relative '../models/constituency.rb'
require_relative '../models/timeline_element.rb'

class GeneralElectionLoader
  def load_from_file(file_name="general_elections.js")
    file = "data/#{file_name}"
    data = JSON.parse(File.read(file))
    data.each do |record|
      election = GeneralElection.new
      election.start_date = record["start_date"]
      election.end_date = record["end_date"]
      election.id = "#{election.start_date.year}-#{election.start_date.month.to_s.rjust(2,"0")}_GeneralElection"
      election.save
    end
  end
end