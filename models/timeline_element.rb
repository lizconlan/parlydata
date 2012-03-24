require 'mongo_mapper'

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

class GeneralElection < TimelineElement
end

class ByElection < TimelineElement
  key :reason, String
end

class Parliament < TimelineElement
  has_many :parly_sessions

  key :number, Integer  
end

class ParlySession < TimelineElement
  belongs_to :parliament
  
  key :reference, String
end