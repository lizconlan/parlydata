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
    list = find_exact_or_fuzzy_match(name.gsub("-upon-", " upon "), year) if list.empty? and name.include?("-upon-")
    list = find_exact_or_fuzzy_match(name.gsub(" le ", "-le-"), year) if list.empty? and name.include?(" le ")
    list = find_exact_or_fuzzy_match(name.gsub("-le-", " le "), year) if list.empty? and name.include?("-le-")
    list = find_exact_or_fuzzy_match(name.gsub(" & ", " and "), year) if list.empty? and name.include?("&")
    list = find_exact_or_fuzzy_match(name.gsub(" and ", " & "), year) if list.empty? and name.include?(" and ")
    if list.empty? and name =~ /(^South |^East |^North |^West )(.*)/
      heading = $1
      the_rest = $2
      if the_rest =~ /(^South |^East |^North |^West )(.*)/
        heading = "#{heading} #{$1}".squeeze(" ").strip
        the_rest = $2
      end
      list = find_exact_or_fuzzy_match("#{the_rest} #{heading}".squeeze(" ").strip, year)
    end
    if list.empty? and name =~ /(.*)( South$| East$| North$| West$)/
      heading = $2
      the_rest = $1
      if the_rest =~ /(.*)( South$| East$| North$| West$)/
        heading = "#{$2} #{heading}".squeeze(" ").strip
        the_rest = $1
      end
      list = find_exact_or_fuzzy_match("#{heading} #{the_rest}".squeeze(" ").strip, year)
    end
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