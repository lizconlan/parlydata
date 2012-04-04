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

get "/api/?" do
  #api documentation page
  File.read(File.join('public/api', 'index.html'))
end

get "/api/constituency/detail.json?" do
  content_type :json
  name = params[:name]
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

get "/api/constituency.json" do
  #json file for Swagger
  %|{"apis":[
      {
        "path":"/constituency/detail.json",
        "description":"Constituency info",
        "operations":[
          {
            "parameters":[
              {
                "name":"name",
                "description":"Constituency name",
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
            "notes":"Returns some stuff",
            "responseTypeInternal":"com.parlydata.api.model.Constituency",
            "errorResponses":[{"reason":"Invalid ID supplied","code":400},{"reason":"Constituency not found","code":404}],
            "nickname":"getDetail",
            "responseClass":"constituency",
            "summary":"Get constituency detail"
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
  %|{"apis":[{"path":"/constituency.{format}","description":"Operations about constituency"}],"basePath":"#{@base_path}","swaggerVersion":"1.1-SHAPSHOT.121026","apiVersion":"1"}|
end