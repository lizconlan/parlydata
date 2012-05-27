require 'mongo_mapper'

class Constituency
  include MongoMapper::Document
  many :elections, :in => :election_ids
  
  key :name, String
  key :year_created, Integer
  key :year_abolished, Integer
  key :election_ids, Array
  
  def self.find_exact_matches_by_year(name ,year)
    c = Constituency.where(:name => /^#{name}$/i, :year_created.lte => year, :year_abolished.gte => year)
    list = c.all
    c = Constituency.where(:name => /^#{name}$/i, :year_created.lte => year, :year_abolished.exists => false)
    list += c.all
  end
  
  def self.find_fuzzy_matches_by_year(name, year)
    c = Constituency.where(:name => /#{name}/i, :year_created.lte => year, :year_abolished.gte => year)
    list = c.all
    c = Constituency.where(:name => /#{name}/i, :year_created.lte => year, :year_abolished.exists => false)
    list += c.all
  end
  
  def self.find_constituency(name, year)
    if name =~ /(\(.*\))/
      bracketed_text = $1
      name = name.gsub('(','\(').gsub(')','\)')
    end
    name = name.gsub(":","") if name.include?(":")
    if name =~ /( and | & )/
      name = name.gsub($1, "(?: and | & )")
    end
    if name =~ /( (?:upon|under|le) |-(?:upon|under|le)-)/
      name = name.gsub($1, " |-#{$1.gsub("-","").strip} |-")
    end
    list = find_exact_or_fuzzy_match(name, year)
    list = find_exact_or_fuzzy_match(name.gsub(",", ""), year) if list.empty? and name.include?(",")
    if list.empty? and bracketed_text
      bracketed_text = bracketed_text.gsub('(','\(').gsub(')','\)')
      name = name.gsub(bracketed_text, "").strip
      list = find_exact_or_fuzzy_match(name, year)
      list = find_exact_or_fuzzy_match(name.gsub(",", ""), year) if list.empty? and name.include?(",")
    end
    if list.empty? and name =~ /(^South |^East |^North |^West |^Mid )(.*)/
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
      if the_rest =~ /(.*)\(\?: and \| & \)(.*)/
        part1 = $1
        part3 = $2
        list = find_exact_or_fuzzy_match("#{part1}(?: and | & )#{heading.strip} #{part3}".squeeze(" ").strip, year)
      else
        list = find_exact_or_fuzzy_match("#{heading} #{the_rest}".squeeze(" ").strip, year)
      end
    end
    list
  end
  
  def storable_name
    name.downcase().gsub(" ","-").gsub('(',"").gsub(')',"")  
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