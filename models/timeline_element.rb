require 'mongo_mapper'
require_relative 'election_result'

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
  has_many :election_results
  
  key :constituency, String
end

class GeneralElection < Election
end

class ByElection < Election
  key :reason, String
end

class Parliament < TimelineElement
  has_many :parliamentary_sessions

  key :number, Integer  
end

class ParliamentarySession < TimelineElement
  belongs_to :parliament
  
  key :reference, String
end