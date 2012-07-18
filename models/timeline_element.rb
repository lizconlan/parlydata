require 'mongo_mapper'
require_relative 'election_win'
require_relative 'constituency'

class TimelineElement
  include MongoMapper::Document
  
  key :_type, String
  key :start_date, Date
  key :end_date, Date
end

class RegnalYear < TimelineElement
  key :monarch, String
  key :year_of_reign, Integer
  key :abbreviation, String
end

class Election < TimelineElement
  many :election_wins, :in => :election_win_ids
  
  key :election_win_ids, Array
end

class GeneralElection < Election
end

class ByElection < Election
  has_one :constituency
  
  key :constituency_id, BSON::ObjectId
  key :reason, String
end

class Parliament < TimelineElement
  has_many :parliamentary_sessions

  key :number, Integer
  key :notes, String
end

class ParliamentarySession < TimelineElement
  belongs_to :parliament
  
  key :reference, String
end