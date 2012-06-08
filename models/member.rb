# encoding: utf-8

require 'mongo_mapper'

class Member
  include MongoMapper::Document
  belongs_to :person
  
  key :_type, String
  key :person_id, BSON::ObjectId
end

class MP < Member
  has_one :election
  
  key :election_id, BSON::ObjectId
end

class Peer < Member
end