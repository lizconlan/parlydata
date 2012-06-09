require 'rest-client'
require 'json'
require 'date'
require_relative '../models/timeline_element'
require_relative '../models/election_result'
require_relative '../models/person'
require_relative '../models/member'

class GeneralElectionResultsLoader
  def load_from_the_guardian()
    # fetch_guardian_data("http://www.guardian.co.uk/politics/api/general-election/2010/results/json", "2010")
    fetch_guardian_data("http://www.guardian.co.uk/politics/api/general-election/2005/results/json", "2005")
    
    # fetch_guardian_data("http://www.guardian.co.uk/politics/api/general-election/2001/results/json", "2001")
    # fetch_guardian_data("http://www.guardian.co.uk/politics/api/general-election/1997/results/json", "1997")
    # fetch_guardian_data("http://www.guardian.co.uk/politics/api/general-election/1992/results/json", "1992")
  end
end

private
  def fetch_guardian_data(url, year)
    response = RestClient.get(url)
    data = JSON.parse(response.body)
    
    election = GeneralElection.find(/^#{year}/)
    
    data["results"]["called-constituencies"].each do |record|
      result = ElectionResult.new
      result.election_id = election.id
      
      constituency_name = record["name"]
      
      #debug
      p "#{constituency_name} - #{record["result"]["winning-mp"]["name"]}"
      
      name = record["result"]["winning-mp"]["name"]
      
      #do person/member stuff
      ##catch mistakes/oddities
      if name == "Andrew Porter" and constituency_name == "Wirral South"
        name = "Barry Porter"
      end
      if name == "Roger Scott" and constituency_name =~ /Wigan/
        name = "Roger Stott"
      end
      name = "Colin Shepherd" if name == "Colin Shephard"
      name = "Katy Clark" if name == "Katy Clarke"
      
      ## reformat as case statement when finished
      if name == "Anthony Wright" and constituency_name == "Great Yarmouth"
        person = [Person.find("Wright_T_1954")]
      elsif name == "Tony Wright" and (constituency_name == "Cannock Chase" or constituency_name == "Cannock and Burntwood")
        person = [Person.find("Wright_T_1948")]
      elsif name == "Angela Smith" and constituency_name == "Basildon"
        person = [Person.find("Smith_A_1959")]
      elsif name == "Angela Smith" and constituency_name == "Sheffield Hillsborough"
        person = [Person.find("Smith_A_1961")]
      elsif name == "Alan Williams" and (constituency_name == "Carmarthen East and Dinefwr" or constituency_name == "Carmarthen")
        person = [Person.find("Williams_A_1945")]
      elsif name == "Alan Williams" and constituency_name == "Swansea West"
        person = [Person.find("Williams_A_1930")]
      elsif name == "Michael Howard" and constituency_name == "Folkestone and Hythe"
        person = [Person.find("Howard_M_1941")]
      elsif name == "Gareth Thomas" and constituency_name == "Harrow West"
        person = [Person.find("Thomas_G_1967")]
      elsif name == "Gareth Thomas" and constituency_name == "Clwyd West"
        person = [Person.find("Thomas_G_1954")]
      elsif name == "John Taylor" and constituency_name == "Solihull"
        person = [Person.find("Taylor_J_1941")]
      elsif name == "John Taylor" and constituency_name == "Strangford"
        person = [Person.find("Taylor_J_1937")]
      elsif name == "Alan Campbell" and constituency_name == "Tynemouth"
        person = [Person.find("Campbell_A_1957")]
      elsif name == "John Smith" and constituency_name == "Vale of Glamorgan"
        person = [Person.find("Smith_J_1951")]
      elsif name == "John Smith" and constituency_name == "Monklands East"
        person = [Person.find("Smith_J_1938")]
      elsif name == "Ian Stewart" and constituency_name == "Eccles"
        person = [Person.find("Stewart_I_1950")]
      elsif name == "John Robertson" and constituency_name == "Glasgow North West"
        person = [Person.find("Robertson_J_1952")]
      elsif name == "David Cairns" and constituency_name == "Inverclyde"
        person = [Person.find("Cairns_D_1966")] #would be caught by the year query
      elsif name == "Robert Hughes" and constituency_name == "Aberdeen North"
        person = [Person.find("Hughes_R_1932")]
      elsif name == "Robert Hughes" and constituency_name == "Harrow West"
        person = [Person.find("Hughes_R_1951")]
      elsif name == "David Young" and constituency_name == "Bolton South East"
        person = [Person.find("Young_D_1930")]
      elsif name == "John Hunt" and constituency_name == "Ravensbourne"
        person = [Person.find("Hunt_J_1929")]
      elsif name == "David Evans" and constituency_name == "Welwyn Hatfield"
        person = [Person.find("Evans_D_1935")]
      elsif name == "Michael Morris" and constituency_name == "Northampton South"
        person = [Person.find("Morris_M_1936")]
      elsif name == "Jim Callaghan" and constituency_name == "Heywood and Middleton"
        person = [Person.find("Callaghan_J_1927")]
      elsif name == "David Anderson" and constituency_name == "Blaydon"
        person = [Person.find("Anderson_D_1953")]
      elsif name == "Philip Dunne" and constituency_name == "Ludlow"
        person = [Person.find("Dunne_P_1958")]
      elsif name == "David Davies" and constituency_name == "Monmouth"
        person = [Person.find("Davies_D_1970")]
      elsif name == "Jeremy Browne" and constituency_name =~ /^Taunton/
        person = [Person.find("Browne_J_1970")]
      else
        person = Person.find_all_by_name(name)
      end
      
      if person.size > 1
        p "found multiple people :("
        raise person.inspect
      else
        person = person.first
      end
      
      p "found: #{person.forenames} #{person.surname}, #{person.born.year}"
      p ""
      
      member = MP.new
      member.person_id = person.id
      member.election_id = election.id
      member.id = "#{person.surname}_#{person.forenames.gsub(" ","-")}_#{year}"
      member.save
      result.member_ids << member.id unless result.member_ids.include?(member.id)
      
      #monkeypatch discrepancies in Guardian data
      constituency_name = monkeypatch_data_pre_2005(constituency_name) if year.to_i < 2005
      constituency_name = monkeypatch_data_1992(constituency_name) if year.to_i == 1992
      
      constituency = Constituency.find_constituency(constituency_name, year.to_i)
      result.constituency_id = constituency.first.id
      
      result.party = record["result"]["winning-mp"]["party"]["name"]
      result.save
    end
  end

  def monkeypatch_data_pre_2005(name)
    case name
    when "Ayrshire Central"
      "Ayr"
    when "Ayr, Carrick and Cumnock"
      "Carrick, Cumnock and Doon Valley"
    when "Glenrothes"
      "Fife Central"
    when "Cumbernauld, Kilsyth and Kirkintilloch East"
      "Cumbernauld and Kilsyth"
    when "Ayrshire North and Arran"
      "Cunninghame North"
    when "Dumfriesshire, Clydesdale and Tweeddale"
      "Dumfries"
    when "Dunfermline and Fife West"
      "Dunfermline West"
    when "East Kilbride, Strathaven and Lesmahagow"
      "East Kilbride"
    when "Dumfries and Galloway"
      "Galloway and Upper Nithsdale"
    when "Glasgow North West"
      "Glasgow Anniesland"
    when "Glasgow East"
      "Glasgow Baillieston"
    when "Glasgow South"
      "Glasgow Cathcart"
    when "Glasgow North"
      "Glasgow Maryhill"
    when "Glasgow South West"
      "Glasgow Pollok"
    when "Rutherglen and Hamilton West"
      "Glasgow Rutherglen"
    when "Glasgow Central"
      "Glasgow Shettleston"
    when "Glasgow North East"
      "Glasgow Springburn"
    when "Inverness, Nairn, Badenoch and Strathspey"
      "Inverness East Nairn and Lochaber"
    when "Kirkcaldy and Cowdenbeath"
      "Kirkcaldy"
    when "Linlithgow and Falkirk East"
      "Linlithgow"
    when "Paisley and Renfrewshire South"
      "Paisley South"
    when "Perth and Perthshire North"
      "Perth"
    when "Ross, Skye and Lochaber"
      "Ross, Skye and Inverness West"
    when "Berwickshire, Roxburgh and Selkirk"
      "Roxburgh and Berwickshire"
    when "Dunbartonshire East"
      "Strathkelvin and Bearsden"
    when "Na h-Eileanan an Iar"
      "Western Isles"
    when "Renfrewshire East"
      "Eastwood"
    when "Edinburgh South West"
      "Edinburgh Pentlands"
    when "Lanark and Hamilton East"
      "Clydesdale"
    when "Coatbridge, Chryston and Bellshill"
      "Coatbridge and Chryston"
    when "Dunbartonshire West"
      "Dumbarton"
    when "Ochil and Perthshire South"
      "Ochil"
    when "Paisley and Renfrewshire North"
      "Paisley North"
    else
      name
    end
  end

  def monkeypatch_data_1992(name)
    case name
    when "Altrincham and Sale West"
      "Altrincham and Sale"
    when "Barnsley East and Mexborough"
      "Barnsley East"
    when "Bethnal Green and Bow"
      "Bethnal Green and Stepney"
    when "Boothferry"
      "Booth Ferry"
    when "Brecon and Radnorshire"
      "Brecon and Radnor"
    when "Montgomeryshire"
      "Montgomery"
    when "Richmond Yorks"
      "Richmond (Yorks)" #should probably fix this in the finder?
    when "Ross, Cromarty and Skye"
      "Ross and Cromarty and Skye"
    when "South West Cambridgeshire"
      "Cambridge South West"
    when "West Renfrewshire and Inverclyde"
      "Renfrew West and Inverclyde"
    else
      name
    end
  end