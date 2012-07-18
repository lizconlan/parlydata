require 'mongo_mapper'

class ElectionWin
  include MongoMapper::Document
  belongs_to :constituency
  many :people, :in => :person_ids
  belongs_to :election
  
  key :election_id, BSON::ObjectId
  key :constituency_id, BSON::ObjectId
  key :party, String
  key :person_ids, Array
end