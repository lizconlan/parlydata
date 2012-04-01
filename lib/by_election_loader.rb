require 'rest-client'
require 'json'
require 'date'
require_relative '../models/constituency.rb'
require_relative '../models/timeline_element.rb'

class ByElectionLoader
  def load_from_file(file_name="by_elections.js")
    file = "data/#{file_name}"
    data = JSON.parse(File.read(file))
    data.each do |record|
      election = ByElection.new
      election.start_date = record["start_date"]
      election.end_date = record["end_date"]
      election.reason = record["reason"]
      candidate_constituencies = Constituency.find_constituency(record["constituency"], election.start_date.year)
      unless candidate_constituencies.empty?
        election.constituency_id = candidate_constituencies.first.id
        if candidate_constituencies.size > 1
          warn "more than one possibility for #{record["constituency"]}"
        end
        constituency = candidate_constituencies.first
        unless constituency.election_ids.include?(election.id)
          constituency.election_ids << election.id
          constituency.save
        end
      else
        warn "#{record["constituency"]} not found :("
      end
      election.save
    end
  end
end