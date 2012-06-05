require 'bundler'
Bundler.setup

require 'rake'
require 'mongo_mapper'

require_relative 'lib/constituency_loader'
require_relative 'lib/regnal_year_loader'
require_relative 'lib/by_election_loader'
require_relative 'lib/general_election_loader'
require_relative 'lib/election_results_loader'
require_relative 'lib/person_loader'

MONGO_URL = ENV['MONGOHQ_URL'] || YAML::load(File.read("config/mongo.yml"))[:mongohq_url]
env = {}
MongoMapper.config = { env => {'uri' => MONGO_URL} }
MongoMapper.connect(env)

desc "load all the data"
task :load_all do
  # cl = ConstituencyLoader.new
  # cl.load_from_scraperwiki()
  # cl.load_changes(2010)
  # 
  # ryl = RegnalYearLoader.new
  # ryl.load_from_scraperwiki()
  #
  per = PersonLoader.new
  per.load_from_scraperwiki()
  #
  # bel = ByElectionLoader.new
  # bel.load_from_file()
  # 
  # gel = GeneralElectionLoader.new
  # gel.load_from_file()
  # 
  #
  # res = GeneralElectionResultsLoader.new
  # res.load_from_the_guardian()
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end