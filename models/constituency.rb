# encoding: utf-8

require 'mongo_mapper'

class Constituency
  include MongoMapper::Document
  many :election_wins, :in => :election_win_ids
  
  key :name, String
  key :year_created, Integer
  key :year_abolished, Integer
  key :election_win_ids, Array
  
  def self.find_exact_matches_by_year(name ,year)
    name.gsub!(/^\*/, "")
    c = Constituency.where(:name => /^#{name}$/i, :year_created.lte => year, "$or" => [{:year_abolished => {"$gte" => year}}, {:year_abolished => {"$exists" => false}}])
    list = c.all
  end
  
  def self.find_fuzzy_matches_by_year(name, year)
    name.gsub!(/^\*/, "")
    c = Constituency.where(:name => /#{name}/i, :year_created.lte => year, "$or" => [{:year_abolished => {"$gte" => year}}, {:year_abolished => {"$exists" => false}}])
    list = c.all
  end
  
  def self.find_constituency(name, year, replace_spaces=nil)
    start_name = name
    if name =~ /(\(.*\))/
      bracketed_text = $1
      name = name.gsub('(','\(').gsub(')','\)')
    end
    name = name.gsub("Tewekesbury", "Tewkesbury")
    name = "Ynys Môn" if name == "Ynys Mon"
    name = name.gsub("Shepherd's Bush", "Shepherds Bush")
    name = "Chester" if name == "City of Chester"
    name = "Durham" if name == "City of Durham"
    name = "York" if name == "City of York"
    name = name.gsub(":","") if name.include?(":")
    
    if name =~ /( (?:upon|under|le) |-(?:upon|under|le)-)/
      name = name.gsub($1, " |-#{$1.gsub("-","").strip} |-")
    else
      name = name.gsub("-", "-| ") unless name =~ /h-Eileanan/
      if replace_spaces
        name = name.gsub(" ", ",? ").gsub(",,?", ",")
      end
    end
    
    if name =~ /( and | & )/
      name = name.gsub($1, "(?: and | & )")
    end
    
    list = find_exact_or_fuzzy_match(name, year)
    list = find_exact_or_fuzzy_match(name.gsub(",", ""), year) if list.empty? and name.include?(",")
    if list.empty? and bracketed_text
      bracketed_text = bracketed_text.gsub('(','\(').gsub(')','\)')
      name = name.gsub(bracketed_text, "").strip
      list = find_exact_or_fuzzy_match(name, year)
      list = find_exact_or_fuzzy_match(name.gsub(",", ""), year) if list.empty? and name.include?(",")
    end
    if list.empty? and name =~ /(^South |^East |^North |^West |^Mid |^Central)(.*)/
      heading = $1
      the_rest = $2
      if the_rest =~ /(^South |^East |^North |^West |^Mid)(.*)/
        heading = "#{heading} #{$1}".squeeze(" ").strip
        the_rest = $2
      end
      if the_rest =~ /(.*)\(\?: and \| & \)(.*)/
        part1 = $1
        part3 = $2
        list = find_exact_or_fuzzy_match("#{part1} #{heading.strip}(?: and | & )#{part3}".squeeze(" ").strip, year)
      else
        list = find_exact_or_fuzzy_match("#{the_rest} #{heading}".squeeze(" ").strip, year)
      end
    end    
    if list.empty? and name =~ /(.*)( South$| East$| North$| West$| Mid$| Central$)/
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
    if list.empty? and name =~ /(.*)(South|East|North|West)\(\?: and \| & \)(.*)/
      part1 = $1
      heading = $2
      part3 = $3
      list = find_exact_or_fuzzy_match("#{heading} #{part1.strip}(?: and | & )#{part3}".squeeze(" ").strip, year)
    end
    if list.empty? and name =~ /(.*)\(\?: and \| & \)(South |East |North |West )(.*)/
      part1 = $1
      heading = $2
      part3 = $3
      list = find_exact_or_fuzzy_match("#{part1}(?: and | & )#{part3} #{heading.strip}".squeeze(" ").strip, year)
    end
    if list.empty? and name =~ /(.*)(South|East|North|West)\(\?: and \| & \)(.*)( South$| East$| North$| West$)/
      part1 = $1
      heading1 = $2
      part2 = $3
      heading2 = $4
      list = find_exact_or_fuzzy_match("#{heading1} #{part1.strip}(?: and | & )#{heading2.strip} #{part2.strip}", year)
    end
    
    unless replace_spaces
      if list.empty?
        list = self.find_constituency(start_name, year, true)
      end
    end
    list
  end
  
  def storable_name
    name.downcase().gsub(" ","-").gsub('(',"").gsub(')',"")  
  end
  
  def to_hash(include_wins=false)
    hash = {:id => id, :name => name, :year_created => year_created}
    hash[:year_abolished] = year_abolished if year_abolished
    if include_wins
      wins = []
      election_wins.each do |win|
        person = win.person
        wins << {:election_id => win.election.id, :mps => {:person_id => win.person_id, :name => "#{person.forenames} #{person.surname}".squeeze(" "), :party => win.party}}
      end
      hash[:wins] = wins unless wins.empty?
    end
    hash
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