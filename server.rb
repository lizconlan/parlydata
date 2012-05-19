require 'sinatra'
require 'mongo_mapper'

MONGO_URL = ENV['MONGOHQ_URL'] || YAML::load(File.read("config/mongo.yml"))[:mongohq_url]
env = {}
MongoMapper.config = { env => {'uri' => MONGO_URL} }
MongoMapper.connect(env)

require_relative "models/constituency"
require_relative "models/timeline_element"

before do
  if request.port != 80
    @base_path = "http://#{request.host}:#{request.port}/api"
  else
    @base_path = "http://#{request.host}/api"
  end
end

get "/" do
  #welcome/intro/human-friendly explanatory page
  "intro text here"
end

get "/api/" do
  redirect "/api"
end

get "/api" do
  #api documentation page
  File.read('public/api/index.html')
end

get "/api/constituencies/search" do
  content_type :json
  name = params[:q]
  year = params[:year]
  if name and year
    constituencies = Constituency.find_constituency(name, year.to_i)
  elsif name
    constituencies = Constituency.find_all_by_name(/#{name}/i)
  end
  unless constituencies.empty?
    constituencies.to_json
  else
    status 404
    %Q|{"message": "Constituency not found", "type": "error"}|
  end
end

get "/api/election/something.json" do
end

get "/api/constituencies/?" do
  content_type :json
  start = params[:start]
  start = start.to_i
  start = 1 if start < 1
  if start > Constituency.all.size
    "[]"
  else
    Constituency.all[start-1..start-1+9].to_json
  end
end

get "/api/constituencies/:id/?" do
  content_type :json
  id = params[:id]
  constituency = Constituency.find(id)
  if constituency
    constituency.to_json
  else
    status 404
    %Q|{"message": "Constituency not found", "type": "error"}|
  end
end

get "/api/constituencies.json" do
  #json file for Swagger
  %|{"apis":[
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
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns a list of constituencies, 10 at a time",
            "responseTypeInternal":"com.parlydata.api.model.Constituency",
            "errorResponses":[],
            "nickname":"getConstituencies",
            "responseClass":"constituency",
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
              }
            ],
            "httpMethod":"GET",
            "notes":"Returns a list of matching constituencies or a 404 error if no matches are found",
            "responseTypeInternal":"com.parlydata.api.model.Constituency",
            "errorResponses":[{"reason":"Constituency not found","code":404}],
            "nickname":"getConsituencySearch",
            "responseClass":"constituency",
            "summary":"Constituency search"
          }
        ]
      }
    ],
    "models": {
      "Constituency":{
        "properties":{
          "election_ids":{"type":"array","items":{"$ref":"election"}},
          "id":{"type":"string"},
          "name":{"type":"string"},
          "year_abolished":{"type":"int"},
          "year_created":{"type":"int"}
        },
        "id":"constituency"
      },
      "Pet":{"properties":{"tags":{"type":"array","items":{"$ref":"tag"}},"id":{"type":"long"},"category":{"type":"category"},"status":{"type":"string","description":"pet status in the store","allowableValues":{"values":["available","pending","sold"],"valueType":"LIST"}},"name":{"type":"string"},"photoUrls":{"type":"array","items":{"type":"string"}}},"id":"pet"},
      "Tag":{"properties":{"id":{"type":"long"},"name":{"type":"string"}},"id":"tag"}
    },
    "basePath":"#{@base_path}",
    "swaggerVersion":"1.1-SHAPSHOT.121026",
    "apiVersion":"1"}|
end

get "/api/resources.json" do
  #resources.json for Swagger
  %|{"apis":[{"path":"/constituencies.{format}","description":"Operations about constituency"}],"basePath":"#{@base_path}","swaggerVersion":"1.1-SHAPSHOT.121026","apiVersion":"1"}|
end