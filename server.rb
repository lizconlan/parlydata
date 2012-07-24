require 'sinatra'
require 'mongo_mapper'

MONGO_URL = ENV['MONGOHQ_URL'] || YAML::load(File.read("config/mongo.yml"))[:mongohq_url]
env = {}
MongoMapper.config = { env => {'uri' => MONGO_URL} }
MongoMapper.connect(env)

require_relative "models/constituency"
require_relative "models/timeline_element"
require_relative "models/person"
require_relative "models/election_win"

before do
  if request.port != 80
    @base_path = "http://#{request.host}:#{request.port}/api"
  else
    @base_path = "http://#{request.host}/api"
  end
end

get "/" do
  #welcome/intro/human-friendly explanatory page
  "[insert explanation of service, available data sets, limitations, acknowledgements]"
end

get "/api/" do
  redirect "/api"
end

get "/api" do
  #api documentation page
  File.read('public/api/index.html')
end

get "/api/constituencies/search/?" do
  content_type :json
  name = params[:q]
  year = params[:year]
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  start = params[:start]
  start = start.to_i
  start = 1 if start < 1
  
  if name and year
    constituencies = Constituency.find_constituency(name, year.to_i, :offset => start-1, :limit => 10)
  elsif name
    constituencies = Constituency.find_all_by_name(/#{name}/i, :offset => start-1, :limit => 10)
  end
  unless constituencies.empty?
    constituencies.map{|x| x.to_hash(include_wins)}.to_json
  else
    status 404
    %Q|{"message": "Constituency not found", "type": "error"}|
  end
end

get "/api/constituencies/?" do
  content_type :json
  start = params[:start]
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  start = start.to_i
  start = 1 if start < 1
  if start > Constituency.count
    "[]"
  else
    Constituency.all(:offset => start-1, :limit => 10).map{|x| x.to_hash(include_wins)}.to_json
  end
end

get "/api/constituencies/:id/?" do
  content_type :json
  id = params[:id]
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  constituency = Constituency.find(id)
  if constituency
    constituency.to_hash(include_wins).to_json
  else
    status 404
    %Q|{"message": "Constituency not found", "type": "error"}|
  end
end

get "/api/elections/?" do
  content_type :json
  type = params[:type]
  start = params[:start]
  start = start.to_i
  start = 1 if start < 1
  
  case type
  when "ByElection"
    elections = ByElection.all(:offset => start-1, :limit => 10).map{|election| {:id => election.id, :type => election._type, :start_date => election.start_date, :end_date => election.end_date}}.to_json
  when "GeneralElection"
    elections = GeneralElection.all(:offset => start-1, :limit => 10).map{|election| {:id => election.id, :type => election._type, :start_date => election.start_date, :end_date => election.end_date}}.to_json
  else
    elections = Election.all(:offset => start-1, :limit => 10).map{|election| {:id => election.id, :type => election._type, :start_date => election.start_date, :end_date => election.end_date}}.to_json
  end
  if elections == "null"
    "[]"
  else
    elections
  end
end

get "/api/elections/:id/?" do
  content_type :json
  id = params[:id]
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  
  election = Election.find(id)
  if election
    hash = {:id => election.id, :type => election._type, :start_date => election.start_date, :end_date => election.end_date}
    wins = []
    if include_wins
      election.election_wins.each do |win|
        wins << {:mp => {:id => win.person_id, :name => win.person_name, :party => win.party}, :constituency_id => win.constituency_id, :constituency_name => win.constituency_name}
      end
      hash[:wins] = wins unless wins.empty?
    end
    hash.to_json
  else
    status 404
    %Q|{"message": "Election not found", "type": "error"}|
  end
end

get "/api/mps/search" do
  content_type :json
  name = params[:q]
  year = params[:year]
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  
  members = Person.find_all_by_name(name)
  members.delete_if { |x| x.election_win_ids.empty? }
  unless members.empty?
    members_json = []
    members.each do |member|
      hash = {:id => "#{member.id}", :name => "#{member.forenames} #{member.surname}", :born => "#{member.born}", :died => "#{member.died}"}
      if include_wins
        hash[:election_wins] = member.election_wins.map {|x| {:type => x.election._type, :constituency_name => x.constituency.name, :party => x.party, :election_date => x.election.start_date}}
      end
      members_json << hash
    end
    members_json.to_json
  else
    status 404
    %Q|{"message": "Member not found", "type": "error"}|
  end
end

get "/api/mps/?" do
  start = params[:start]
  start = start.to_i
  start = 0 if start < 2
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  
  members = Person.where(:election_win_ids.ne => []).limit(10).skip(start)
  members_hash = []
  members.each do |member|
    hash = {:id => "#{member.id}", :name => "#{member.forenames} #{member.surname}", :born => "#{member.born}", :died => "#{member.died}"}
    if include_wins
      hash[:election_wins] = member.election_wins.map {|x| {:type => x.election._type, :constituency_name => x.constituency.name, :party => x.party, :election_date => x.election.start_date}}
    end
    members_hash << hash
  end
  members_hash.to_json
end

get "/api/mps/:id/?" do
  content_type :json
  id = params[:id]
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  member = Person.find(id)
  if member
    hash = {:id => "#{member.id}", :name => "#{member.forenames} #{member.surname}", :born => "#{member.born}", :died => "#{member.died}"}
    if include_wins
      hash[:election_wins] = member.election_wins.map {|x| {:type => x.election._type, :constituency_name => x.constituency.name, :party => x.party, :election_date => x.election.start_date}}
    end
    hash.to_json
  else
    status 404
    %Q|{"message": "MP not found", "type": "error"}|
  end
end


#Swagger things
get "/api/constituencies.json" do
  #json file for Swagger
  %|{"apiVersion": "1.0",
    "swaggerVersion": "1.0",
    "basePath": "#{@base_path}",
    "resourcePath": "/constituencies",
    "apis":[
      {
        "path":"/constituencies",
        "description":"List of constituencies",
        "operations":[
          {
            "parameters":[
              {
                "name":"start",
                "description":"Offset parameter for pagination",
                "dataType":"integer",
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              },
              {
                "name":"include_wins",
                "description":"Optionally return the election result data (accepts true or 1)",
                "dataType":"string",
                "required":false,
                "allowableValues": {
                    "valueType": "LIST",
                    "values": ["1", "true"]
                },
                "allowMultiple":false,
                "paramType":"query"
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns a list of constituencies, 10 at a time",
            "responseTypeInternal":"com.parlydata.api.model.Constituency",
            "errorResponses":[],
            "nickname":"getConstituencies",
            "responseClass":"List[constituency]",
            "summary":"Constituency list"
          }
        ]
      },
      {
        "path":"/constituencies/{constituencyID}",
        "description":"Constituency detail",
        "operations":[
          {
            "parameters":[
              {
                "name":"constituencyID",
                "description":"ID of the constituency to be fetched",
                "dataType":"string",
                "required":true,
                "allowMultiple":false,
                "paramType":"path"
              },
              {
                "name":"include_wins",
                "description":"Optionally return the election result data (accepts true or 1)",
                "dataType":"string",
                "required":false,
                "allowableValues": {
                    "valueType": "LIST",
                    "values": ["1", "true"]
                },
                "allowMultiple":false,
                "paramType":"query"
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns an individual constituency record, or a 404 error if no match is found",
            "responseTypeInternal":"com.parlydata.api.model.Constituency",
            "errorResponses":[{"reason":"Constituency not found","code":404}],
            "nickname":"getConstituency",
            "responseClass":"constituency",
            "summary":"Get constituency by ID"
          }
        ]
      },
      {
        "path":"/constituencies/search",
        "description":"Constituency search",
        "operations":[
          {
            "parameters":[
              {
                "name":"q",
                "description":"Search query (For best results, use a constituency name)",
                "dataType":"string",
                "required":true,
                "allowMultiple":false,
                "paramType":"query"
              },
              {
                "name":"year",
                "description":"Year",
                "dataType":"int",
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              },
              {
                "name":"include_wins",
                "description":"Optionally return the election result data (accepts true or 1)",
                "dataType":"string",
                "allowableValues": {
                    "valueType": "LIST",
                    "values": ["1", "true"]
                },
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              },
              {
                "name":"start",
                "description":"Offset parameter for pagination",
                "dataType":"integer",
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns a list of matching constituencies or a 404 error if no matches are found",
            "responseTypeInternal":"com.parlydata.api.model.Constituency",
            "errorResponses":[{"reason":"Constituency not found","code":404}],
            "nickname":"getConsituencySearch",
            "responseClass":"List[constituency]",
            "summary":"Constituency search"
          }
        ]
      }
    ],
    "models": {
      "Constituency":{
        "properties":{
          "id":{"type":"string"},
          "name":{"type":"string"},
          "year_created":{"type":"int"},
          "year_abolished":{"type":"int"},
          "wins":{"type":"array","items":{"$ref":"election", "mps": {"type":"array", "items":{"$ref":"mp", "name":{"type":"string"}, "party":{"type":"string"}}}}}
        },
        "id":"constituency"
      }
    }}|
end

get "/api/elections.json" do
  #json file for Swagger
  %|{"apiVersion": "1.0",
    "swaggerVersion": "1.0",
    "basePath": "#{@base_path}",
    "resourcePath":"/elections",
    "apis":[
      {
        "path":"/elections",
        "description":"List of elections",
        "operations":[
          {
            "parameters":[
              {
                "name":"start",
                "description":"Offset parameter for pagination",
                "dataType":"integer",
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              },
              {
                "name":"type",
                "description":"Optional election type to filter by - ByElection or GeneralElection",
                "dataType":"string",
                "allowableValues": {
                    "valueType": "LIST",
                    "values": ["GeneralElection", "ByElection"]
                },
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns a list of elections, 10 at a time",
            "responseTypeInternal":"com.parlydata.api.model.Election",
            "errorResponses":[],
            "nickname":"getElections",
            "responseClass":"List[election]",
            "summary":"Election list"
          }
        ]
      },
      {
        "path":"/elections/{electionID}",
        "description":"Election detail",
        "operations":[
          {
            "parameters":[
              {
                "name":"electionID",
                "description":"ID of the election to be fetched",
                "dataType":"string",
                "required":true,
                "allowMultiple":false,
                "paramType":"path"
              },
              {
                "name":"include_wins",
                "description":"Optionally return the election result data (accepts true or 1)",
                "dataType":"string",
                "allowableValues": {
                    "valueType": "LIST",
                    "values": ["1", "true"]
                },
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns an individual election record, or a 404 error if no match is found",
            "responseTypeInternal":"com.parlydata.api.model.Election",
            "errorResponses":[{"reason":"Election not found","code":404}],
            "nickname":"getElection",
            "responseClass":"election",
            "summary":"Get election by ID"
          }
        ]
      }
    ],
    "models": {
      "Election":{
        "properties":{
          "id":{"type":"string"},
          "type":{"type":"string"},
          "start_date":{"type":"string"},
          "end_date":{"type":"string"},
          "wins":{"type":"array","items":{"mps":{"$ref":"mp","name":{"type":"string"},"party":{"type":"string"}},"$ref":"constituency","constituency_name":{"type":"string"}}}
        },
        "id":"election"
      }
    }}|
end

get "/api/mps.json" do
  #json file for Swagger
  %|{"apiVersion": "1.0",
    "swaggerVersion": "1.0",
    "basePath": "#{@base_path}",
    "resourcePath":"/mps",
    "apis":[
      {
        "path":"/mps",
        "description":"List of MPs",
        "operations":[
          {
            "parameters":[
              {
                "name":"start",
                "description":"Offset parameter for pagination",
                "dataType":"integer",
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              },
              {
                "name":"include_wins",
                "description":"Optionally return the election result data (accepts true or 1)",
                "dataType":"string",
                "allowableValues": {
                    "valueType": "LIST",
                    "values": ["1", "true"]
                },
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns a list of MPs, 10 at a time",
            "responseTypeInternal":"com.parlydata.api.model.MP",
            "errorResponses":[],
            "nickname":"getMPs",
            "responseClass":"List[mp]",
            "summary":"MP list"
          }
        ]
      },
      {
        "path":"/mps/{mpID}",
        "description":"MP detail",
        "operations":[
          {
            "parameters":[
              {
                "name":"mpID",
                "description":"ID of the MP to be fetched",
                "dataType":"string",
                "required":true,
                "allowMultiple":false,
                "paramType":"path"
              },
              {
                "name":"include_wins",
                "description":"Optionally return the election result data (accepts true or 1)",
                "dataType":"string",
                "allowableValues": {
                    "valueType": "LIST",
                    "values": ["1", "true"]
                },
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns an individual MP record, or a 404 error if no match is found",
            "responseTypeInternal":"com.parlydata.api.model.MP",
            "errorResponses":[{"reason":"MP not found","code":404}],
            "nickname":"getMP",
            "responseClass":"mp",
            "summary":"Get MP by ID"
          }
        ]
      },
      {
        "path":"/mps/search",
        "description":"MP search",
        "operations":[
          {
            "parameters":[
              {
                "name":"q",
                "description":"Search query (For best results, use a name)",
                "dataType":"string",
                "required":true,
                "allowMultiple":false,
                "paramType":"query"
              },
              {
                "name":"year",
                "description":"Year",
                "dataType":"int",
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              },
              {
                "name":"include_wins",
                "description":"Optionally return the election result data (accepts true or 1)",
                "dataType":"string",
                "allowableValues": {
                    "valueType": "LIST",
                    "values": ["1", "true"]
                },
                "required":false,
                "allowMultiple":false,
                "paramType":"query"
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns a list of matching MPs or a 404 error if no matches are found",
            "responseTypeInternal":"com.parlydata.api.model.MP",
            "errorResponses":[{"reason":"MP not found","code":404}],
            "nickname":"getMPSearch",
            "responseClass":"List[mp]",
            "summary":"MP search"
          }
        ]
      }
    ],
    "models": {
      "MP":{
        "properties":{
          "id":{"type":"string"},
          "name":{"type":"string"},
          "born":{"type":"string"},
          "died":{"type":"string"},
          "election_wins":{"type":"array","items":{"$ref":"election", "type":{"type":"string"},"constituency":{"type":"string"},"party":{"type":"string"},"election_date":{"type":"string"}}}
        },
        "id":"mp"
      }
    }
  }|
end

get "/api/resources.json" do
  #resources.json for Swagger
  %|{"apiVersion":"1","swaggerVersion":"1.0","basePath":"#{@base_path}","apis":[{"path":"/constituencies.{format}","description":"Operations about constituencies"}, {"path":"/elections.{format}","description":"Operations about elections"}, {"path":"/mps.{format}","description":"Operations about MPs"}]}|
end