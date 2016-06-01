require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'pry'

EMPTY_DB = 'spec/test.sqlite3'
DEV_DB   = 'tmp/run.sqlite3'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

task :run do
  FileUtils.cp(EMPTY_DB, DEV_DB) unless File.exist?(DEV_DB)
  require 'rails_event_store'
  RailsEventStoreActiveRecord::Event.establish_connection(
    :adapter => 'sqlite3',
    :database => DEV_DB
  )
  pry
end

task :clean do
  FileUtils.rm(DEV_DB) if File.exist?(DEV_DB)
end

task start: [:clean, :run]
