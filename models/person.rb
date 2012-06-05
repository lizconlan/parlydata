require 'mongo_mapper'

class Person
  include MongoMapper::Document
  
  key :title, String
  key :forenames, String
  key :surname, String
  key :born, Date
  key :died, Date
  key :url, String
end