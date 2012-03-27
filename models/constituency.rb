require 'mongo_mapper'

class Constituency
  include MongoMapper::Document
  
  key :name, String
  key :year_created, Integer
  key :year_abolished, Integer
end