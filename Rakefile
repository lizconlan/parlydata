require 'bundler'
Bundler.setup

require 'rake'
require 'mongo_mapper'

require_relative 'lib/constituency_loader'
require_relative 'lib/regnal_year_loader'
require_relative 'lib/by_election_loader'
require_relative 'lib/general_election_loader'
require_relative 'lib/election_results_loader'
require_relative 'lib/parliament_loader'
require_relative 'lib/session_loader'
require_relative 'lib/person_loader'
require_relative 'lib/role_appointments_loader'

MONGO_URL = ENV['MONGOHQ_URL'] || YAML::load(File.read("config/mongo.yml"))[:mongohq_url]
env = {}
MongoMapper.config = { env => {'uri' => MONGO_URL} }
MongoMapper.connect(env)

desc "load all the data"
task :load_all do
  Rake::Task["load_constituencies"].invoke
  Rake::Task["load_parliaments"].invoke
  Rake::Task["load_sessions"].invoke
  Rake::Task["load_regnal_years"].invoke
  Rake::Task["load_person_data"].invoke
  Rake::Task["load_by_elections"].invoke
  Rake::Task["load_general_elections"].invoke
  Rake::Task["load_appointments"].invoke
  Rake::Task["load_results"].invoke
end

task :load_constituencies do
  cl = ConstituencyLoader.new
  cl.load_from_scraperwiki()
  cl.load_changes(2010)
end

task :load_parliaments do
  prl = ParliamentLoader.new
  prl.load_from_file()
end

task :load_sessions do
  ses = SessionLoader.new
  ses.load_from_scraperwiki()
end

task :load_regnal_years do
  ryl = RegnalYearLoader.new
  ryl.load_from_scraperwiki()
end

task :load_person_data do
  per = PersonLoader.new
  per.load_from_scraperwiki()
end

task :load_by_elections do
  bel = ByElectionLoader.new
  bel.load_from_file()
end

task :load_general_elections do
  gel = GeneralElectionLoader.new
  gel.load_from_file()
end

task :load_appointments do
  role = RoleAppointmentsLoader.new
  role.load_from_scraperwiki()
end

task :load_results do
  res = GeneralElectionResultsLoader.new
  res.load_from_the_guardian()
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push "lib"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end