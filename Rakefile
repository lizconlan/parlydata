require 'bundler'
Bundler.setup

require 'rake'
require 'mongo_mapper'

require_relative 'lib/constituency_loader'
require_relative 'lib/regnal_year_loader'
require_relative 'lib/by_election_loader'
require_relative 'lib/general_election_loader'

MONGO_URL = ENV['MONGOHQ_URL'] || YAML::load(File.read("config/mongo.yml"))[:mongohq_url]
env = {}
MongoMapper.config = { env => {'uri' => MONGO_URL} }
MongoMapper.connect(env)

desc "load all the data"
task :load_all do
  # cl = ConstituencyLoader.new
  # cl.load_from_scraperwiki()
  # 
  # ryl = RegnalYearLoader.new
  # ryl.load_from_scraperwiki()
  # 
  # bel = ByElectionLoader.new
  # bel.load_from_file()
  
  gel = GeneralElectionLoader.new
  gel.load_from_file()
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end