require 'bundler'
Bundler.setup

require 'rake'
require 'mongo_mapper'

require_relative 'lib/constituency_loader'
require_relative 'lib/regnal_year_loader'

MONGO_URL = ENV['MONGOHQ_URL'] || YAML::load(File.read("config/mongo.yml"))[:mongohq_url]
env = {}
MongoMapper.config = { env => {'uri' => MONGO_URL} }
MongoMapper.connect(env)

desc "load all the data"
task :load_all do
  cl = ConstituencyLoader.new
  cl.load_from_scraperwiki()
  
  ryl = RegnalYearLoader.new
  ryl.load_from_scraperwiki()
end