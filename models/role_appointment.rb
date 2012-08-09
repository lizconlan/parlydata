# encoding: utf-8

require 'mongo_mapper'

class RoleAppointment
  include MongoMapper::Document
  belongs_to :person
  
  key :title, String
  key :appointed, Date
  key :left_role, Date
end