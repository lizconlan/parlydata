require 'rest-client'
require 'json'
require 'date'
require_relative '../models/timeline_element.rb'
require_relative '../models/election_result.rb'

class GeneralElectionResultsLoader
  def load_from_the_guardian()
    fetch_guardian_data("http://www.guardian.co.uk/politics/api/general-election/2010/results/json", "2010")
    fetch_guardian_data("http://www.guardian.co.uk/politics/api/general-election/2005/results/json", "2005")
    fetch_guardian_data("http://www.guardian.co.uk/politics/api/general-election/2001/results/json", "2001")
    fetch_guardian_data("http://www.guardian.co.uk/politics/api/general-election/1997/results/json", "1997")
    fetch_guardian_data("http://www.guardian.co.uk/politics/api/general-election/1992/results/json", "1992")
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
    when "Cirencester and Tewekesbury"
      "Cirencester and Tewkesbury"
    else
      name
    end
  end