require 'mongo_mapper'

class Constituency
  include MongoMapper::Document
  
  key :name, String
  key :year_created, Integer
  key :year_abolished, Integer
  
  def self.find_exact_matches_by_year(name ,year)
    c = Constituency.where(:name => name, :year_created.lte => year, :year_abolished.gte => year)
    list = c.all
    c = Constituency.where(:name => name, :year_created.lte => year, :year_abolished.exists => false)
    list += c.all
  end
  
  def self.find_fuzzy_matches_by_year(name, year)
    c = Constituency.where(:name => /#{name}/i, :year_created.lte => year, :year_abolished.gte => year)
    list = c.all
    c = Constituency.where(:name => /#{name}/i, :year_created.lte => year, :year_abolished.exists => false)
    list += c.all
  end
  
  def self.find_constituency(name, year)
    name = name.gsub(":","") if name.include?(":")
    list = find_exact_or_fuzzy_match(name, year)
    list = find_exact_or_fuzzy_match(name.gsub(" upon ", "-upon-"), year) if list.empty? and name.include?(" upon ")
    list = find_exact_or_fuzzy_match(name.gsub(" le ", "-le-"), year) if list.empty? and name.include?(" le ")
    list = find_exact_or_fuzzy_match(name.gsub(" & ", " and "), year) if list.empty? and name.include?("&")
    list = find_exact_or_fuzzy_match(name.gsub(" and ", " & "), year) if list.empty? and name.include?(" and ")
    list
  end
  
  private
    def self.find_exact_or_fuzzy_match(name, year)
      list = Constituency.find_exact_matches_by_year(name, year)
      if list.empty?
        list = Constituency.find_fuzzy_matches_by_year(name, year)
      end
      list
    end
end