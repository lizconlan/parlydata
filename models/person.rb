# encoding: utf-8

require 'mongo_mapper'

class Person
  include MongoMapper::Document
  many :election_wins, :in => :election_win_ids
  
  key :title, String
  key :forenames, String
  key :surname, String
  key :aka, Array
  key :born, Date
  key :died, Date
  key :url, String
  key :election_win_ids, Array
  
  def add_aka(name)
    aka << name unless aka.include?(name)
  end
  
  def self.find_all_by_name(name, year=nil)
    parts = name.split
    surname = parts.pop
    forenames = parts.join(" ")
    alt_forenames = nil
    alt_surname = nil
    
    #look for a match
    persons = find_people(name, /^#{surname}$/i, forenames)
    
    return persons unless persons.empty?
    
    #empty? see if part of the surname has been misidentified as a middle name
    if parts.count > 1
      parts = forenames.split(" ")
      extra = parts.pop
      alt_forenames = parts.join(" ")
      alt_surname = "#{extra} #{surname}"
      persons = find_people(name, /^#{alt_surname}$/i, alt_forenames)
    end
    
    return persons unless persons.empty?
    
    #still empty? ok, look for known anomalies...
    
    #expected character encoding issues
    surname = "Öpik" if surname == "Opik"
    
    #known spelling errors
    if forenames == "Paul" and surname == "Farelly"
      surname = "Farrelly"
    end
    if forenames == "Peter" and surname == "Horndern"
      surname = "Hordern"
    end
    if forenames == "Irvine" and surname == "Patrick"
      surname = "Patnick"
    end
    
    #and oddities
    if forenames == "William" and surname == "Smyth"
      forenames = "Martin"
    end
    
    #forename shortenings, lengthenings, etc...
    forenames = forename_variations(forenames)
    persons = find_people(name, /^#{surname}$/i, /#{forenames}/)
    
    if persons.empty? and alt_surname
      forenames = forename_variations(alt_forenames)
      persons = find_people(name, /^#{alt_surname}$/i, /#{forenames}/)
    end
    
    persons
  end
  
  private
    def self.find_people(name, surname, forenames, year=nil)
      persons = Person.find_all_by_surname_and_forenames(surname, forenames)
      persons += Person.find_all_by_aka(name)
      persons
    end
    
    def self.forename_variations(forenames)
      case forenames
      when "Michael"        
        forenames = forenames.gsub("Michael", "(?:Michael)|(?:Mick)|(?:Mike)")
      when "Sion"
        forenames = "Siôn"
      when "Sian"
        forenames = "Siân"
      when /(Ste(?:(?:ph)|v)en)/
        forenames = forenames.gsub($1, "(?:Stephen)|(?:Steven)|(?:Steve)")
      when "Llewellyn"
        forenames = forenames.gsub("Llewellyn", "Llew")
      when /((?:Christine)|(?:Christopher))/
        forenames = forenames.gsub($1, "Chris")
      when /(Phill?ip)/
        forenames = forenames.gsub($1, "Phil")
      when "Peter"
        forenames = "Pete"
      when "James"
        forenames = "Jim"
      when "Robert"
        forenames = /(?:B|R)ob/
      when "Jennifer"
        forenames = "Jenny"
      when "Andy"
        forenames = "Andrew"
      when /Anth?ony/
        forenames = "Tony"
      when "Lawrence"
        forenames = "Lawrie"
      when "Nicholas"
        forenames = "Nick"
      when "Thomas"
        forenames = "Tom"
      when "Marek"
        forenames = "Mark"
      when "Desmond"
        forenames = "Des"
      when "Raymond"
        forenames = "Ray"
      when "William"
        forenames = /(?:W|B)ill/
      when "Jeffrey"
        forenames = "Jeff"
      when "Archibald"
        forenames = "Archie"
      when "Elizabeth"
        forenames = "Liz"
      when "Edward"
        forenames = /(?:Ed)|(?:Ted)/
      when "Marjorie"
        forenames = "Mo"
      when "Timothy"
        forenames = "Tim"
      when "Joe"
        forenames = "Joseph"
      when "Alfred"
        forenames = "Alf"
      when "Ronald"
        forenames = "Ron"
      when "Stanley"
        forenames = "Stan"
      when "Terence"
        forenames = "Terry"
      when "Douglas"
        forenames = "Doug"
      when "Gregory"
        forenames = "Greg"
      when "Benedict"
        forenames = "Ben"
      when "Ben"
        forenames = /(?:Benjamin)|(?:Benedict)/
      end
      forenames
    end
end