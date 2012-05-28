require 'mongo_mapper'

class ElectionResult
  include MongoMapper::Document
  has_one :constituency
  belongs_to :election
  
  key :_type, String
  key :election_id, BSON::ObjectId
  key :constituency_id, BSON::ObjectId
  #key :member_id, BSON::ObjectId
  key :party, String
end