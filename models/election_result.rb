require 'mongo_mapper'

class ElectionResult
  include MongoMapper::Document
  has_one :constituency
  many :members, :in => :member_ids
  belongs_to :election
  
  key :_type, String
  key :election_id, BSON::ObjectId
  key :constituency_id, BSON::ObjectId
  key :party, String
  key :member_ids, Array
end