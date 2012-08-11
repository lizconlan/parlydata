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
require_relative "models/role_appointment"

before do
  if request.port != 80
    @base_path = "http://#{request.host}:#{request.port}/api"
  else
    @base_path = "http://#{request.host}/api"
  end
end

get "/" do
  #welcome/intro/human-friendly explanatory page
  response['Cache-Control'] = "public, max-age=43200"
  File.read('public/index.html')
end

get "/api/" do
  redirect "/api"
end

get "/api" do
  #api documentation page
  response['Cache-Control'] = "public, max-age=43200"
  File.read('public/api/index.html')
end

get "/api/constituencies/search/?" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
  name = params[:q]
  year = params[:year]
  count = 0
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
    count = Constituency.find_constituency(name, year.to_i).count
  elsif name
    constituencies = Constituency.find_all_by_name(/#{name}/i, :offset => start-1, :limit => 10)
    count = Constituency.find_all_by_name(/#{name}/i).count
  end
  unless constituencies.empty?
    {"count" => count, :constituencies => constituencies.map{|x| x.to_hash(include_wins)}}.to_json
  else
    status 404
    %Q|{"message": "Constituency not found", "type": "error"}|
  end
end

get "/api/constituencies/?" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
  start = params[:start]
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  start = start.to_i
  start = 1 if start < 1
  count = Constituency.count
  if start > count
    "[]"
  else
    {"count" => count, :constituencies => Constituency.all(:offset => start-1, :limit => 10).map{|x| x.to_hash(include_wins)}}.to_json
  end
end

get "/api/constituencies/:id/?" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
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
  response['Cache-Control'] = "public, max-age=3600"
  
  type = params[:type]
  start = params[:start]
  start = start.to_i
  start = 1 if start < 1
  count = 0
  
  case type
  when "ByElection"
    count = ByElection.count
    elections = ByElection.all(:offset => start-1, :limit => 10).map{|election| {:id => election.id, :type => election._type, :start_date => election.start_date, :end_date => election.end_date}}
  when "GeneralElection"
    count = GeneralElection.count
    elections = GeneralElection.all(:offset => start-1, :limit => 10).map{|election| {:id => election.id, :type => election._type, :start_date => election.start_date, :end_date => election.end_date}}
  else
    count = Election.count
    elections = Election.all(:offset => start-1, :limit => 10).map{|election| {:id => election.id, :type => election._type, :start_date => election.start_date, :end_date => election.end_date}}
  end
  if elections == "null"
    "[]"
  else
    {"count" => count, :elections => elections}.to_json
  end
end

get "/api/elections/:id/?" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
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
  response['Cache-Control'] = "public, max-age=3600"
  
  name = params[:q]
  year = params[:year]
  year = nil if year.to_i < 1
  start = params[:start]
  start = start.to_i
  start = 0 if start < 2  
  count = 0
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  
  if year
    count = Person.find_all_by_aka(/#{name}/i, "$or" => [{:died => nil},{:died => {"$gte" => "#{year}-01-01".to_time}}], :born.lte => "#{year}-01-01".to_time, :election_win_ids.ne => []).count
    members = Person.find_all_by_aka(/#{name}/i, "$or" => [{:died => nil},{:died => {"$gte" => "#{year}-01-01".to_time}}], :born.lte => "#{year}-01-01".to_time, :election_win_ids.ne => [], :limit => 10, :skip => start)
  else
    count = Person.find_all_by_aka(/#{name}/i, :election_win_ids.ne => []).count
    members = Person.find_all_by_aka(/#{name}/i, :election_win_ids.ne => [], :limit => 10, :skip => start)
  end
  unless members.empty?
    members_json = []
    members.each do |member|
      hash = {:id => "#{member.id}", :name => "#{member.forenames} #{member.surname}", :born => "#{member.born}", :died => "#{member.died}"}
      if include_wins
        hash[:election_wins] = member.election_wins.map {|x| {:type => x.election._type, :constituency_name => x.constituency.name, :party => x.party, :election_date => x.election.start_date}}
      end
      members_json << hash
    end
    {"count" => count, :members => members_json}.to_json
  else
    status 404
    %Q|{"message": "Member not found", "type": "error"}|
  end
end

get "/api/mps/?" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
  start = params[:start]
  start = start.to_i
  start = 0 if start < 2
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  
  count = members = Person.where(:election_win_ids.ne => []).count
  members = Person.where(:election_win_ids.ne => []).limit(10).skip(start)
  members_hash = []
  members.each do |member|
    hash = {:id => "#{member.id}", :name => "#{member.forenames} #{member.surname}", :born => "#{member.born}", :died => "#{member.died}"}
    if include_wins
      hash[:election_wins] = member.election_wins.map {|x| {:type => x.election._type, :constituency_name => x.constituency.name, :party => x.party, :election_date => x.election.start_date}}
    end
    members_hash << hash
  end
  {"count" => count, :members => members_hash}.to_json
end

get "/api/mps/:id/?" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
  id = params[:id]
  if params[:include_wins] == "true" or params[:include_wins] == "1"
    include_wins = true
  else
    include_wins = false
  end
  member = Person.find(id)
  if member
    hash = {:id => "#{member.id}", :name => "#{member.forenames} #{member.surname}", :born => "#{member.born}", :died => "#{member.died}"}
    if member.role_appointments
      hash[:roles] = []
      member.role_appointments.each do |role|
        hash[:roles] << "#{role.title} #{role.appointed.strftime('%d %B %Y')} to #{role.left_role ? role.left_role.strftime('%d %B %Y') : "present"}"
      end
    end
    if include_wins
      hash[:election_wins] = member.election_wins.map {|x| {:type => x.election._type, :constituency_name => x.constituency.name, :party => x.party, :election_date => x.election.start_date}}
    end
    hash.to_json
  else
    status 404
    %Q|{"message": "MP not found", "type": "error"}|
  end
end

get "/api/date-lookup/?" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
  q = params[:date]
  begin
    qdate = Time.parse(q)
  rescue
    qdate = nil
  end
  unless qdate
    status 400
    %Q|{"message": "Invalid date supplied"}|
  else
    qdate = (qdate + qdate.utc_offset).utc
    results = TimelineElement.where(:start_date.lte => qdate, "$or" => [{:end_date => {"$gte" => qdate}}, {:end_date => nil}]).all
    
    stuff = []
    results.each do |widget|
      case widget._type
      when "RegnalYear"
        stuff << {"type" => widget._type, "monarch" => widget.monarch, "year_of_reign" => widget.year_of_reign, "abbreviation" => widget.abbreviation}
      when "Parliament"
        stuff << {"type" => widget._type, "number" => widget.number}
      when "ParliamentarySession"
        stuff << {"type" => widget._type, "reference" => widget.reference}
      when "GeneralElection"
        stuff << {"type" => widget._type, "date" => widget.start_date, "id" => widget.id}
      when "ByElection"
        stuff << {"type" => widget._type, "date" => widget.start_date, "constituency" => widget.constituency.name, "reason" => widget.reason, "id" => widget.id }
      else
        stuff << widget
      end
    end
    
    stuff.to_json
  end
end


#Swagger things
get "/api/constituencies.json" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
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
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
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

get "/api/date-lookup.json" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
  #json file for Swagger
  %|{"apiVersion": "1.0",
    "swaggerVersion": "1.0",
    "basePath": "#{@base_path}",
    "resourcePath": "/date-lookup",
    "apis": [
      {
        "path":"/date-lookup",
        "description":"Get a list of Time Elements for a given date",
        "operations":[
          {
            "parameters":[
              {
                "name":"date",
                "description":"Date to do the lookup against",
                "dataType":"date",
                "required":true,
                "allowMultiple":false,
                "paramType":"query"
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns a list of matching MPs or a 404 error if no matches are found",
            "responseTypeInternal":"com.parlydata.api.model.TimeElement",
            "errorResponses":[{"reason":"Invalid date supplied","code":400}],
            "nickname":"getDateLookup",
            "responseClass":"List[TimeElement,Election]",
            "summary":"Date lookup"
          }
        ]
      }
    ],
    "models": {
      "TimeElement":{
        "properties":{
          "type":{"type":"string"},
          "monarch":{"type":"string"},
          "year_of_reign":{"type":"integer"},
          "abbreviation":{"type":"string"},
          "reference":{"type":"string"},
          "number":{"type":"integer"}
        },
        "id":"time_element"
      }
    }
  }|
end

get "/api/mps.json" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
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
                "description":"ID of the MP record to be fetched",
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
          "roles":{"type":"array","items":{"type":"string"}},
          "election_wins":{"type":"array","items":{"$ref":"election", "type":{"type":"string"},"constituency":{"type":"string"},"party":{"type":"string"},"election_date":{"type":"string"}}}
        },
        "id":"mp"
      }
    }
  }|
end

get "/api/resources.json" do
  content_type :json
  response['Cache-Control'] = "public, max-age=3600"
  
  #resources.json for Swagger
  %|{"apiVersion":"1","swaggerVersion":"1.0","basePath":"#{@base_path}","apis":[{"path":"/constituencies.{format}","description":"Operations about constituencies"}, {"path":"/elections.{format}","description":"Operations about elections"}, {"path":"/mps.{format}","description":"Operations about MPs"}, {"path":"/date-lookup.{format}","description":"Lookup on Time Elements by date"}]}|
end