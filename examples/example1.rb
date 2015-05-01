#!/usr/bin/env ruby

require 'pathname'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path(
  '../Gemfile',
  Pathname.new(__FILE__).realpath
)
require 'rubygems'
require 'bundler/setup'

require 'simple_stats_store/server'
require 'simple_stats_store/file_dump'

require 'fileutils'
require 'sqlite3'
require 'active_record'
require 'terminal-table'

# Set up data dump directory
dump_dir = '/tmp/sss_test'
FileUtils.rm_rf(dump_dir) if Dir.exists?(dump_dir)
Dir.mkdir(dump_dir)
data_dump = SimpleStatsStore::FileDump.new(dump_dir)

# Set up database
db_file = '/tmp/sss.db'
FileUtils.rm(db_file) if File.exists?(db_file)
ActiveRecord::Base.establish_connection(
  adapter: :sqlite3,
  database: db_file
)
ActiveRecord::Schema.define do
  create_table :stats do |table|
    table.column :timestamp, :string
    table.column :pid, :integer
    table.column :load1, :float
    table.column :load5, :float
    table.column :load15, :float
  end
end
class Stats < ActiveRecord::Base
end
models = { stats: Stats }

# Start the server
t_next = Time.new + 5
pid = SimpleStatsStore::Server.new(
  data_dump: data_dump,
  models: models
).run do
  if Time.new >= t_next
    puts "Data at #{Time.new}"
    table = Terminal::Table.new headings: ['Timestamp', 'PID', 'Load 1', 'Load 5', 'Load 15']
    count = 0
    Stats.all.each do |line|
      table << [line.timestamp, line.pid, line.load1, line.load5, line.load15]
      count += 1
    end
    puts table
    puts "#{count} lines"
    puts "\n\n"
    t_next += 5
  end
end

puts "Server pid: #{pid}"

clients = []
# 5 processes set off at the same time.
# These would have problems of contention if accessing SQLite directly.
5.times do
  p = Process.fork do
    # Write statistics for one minute at 2 second intervals
    30.times do
      iostat = `iostat`.split(/\n/)[2].strip.split(/\s+/)
      data_dump.write('stats', { timestamp: Time.new.to_s, pid: $$, load1: iostat[6], load5: iostat[7], load15: iostat[8] } )
      sleep 2
    end
  end
  clients << p
  Process.detach p
end

# Wait for each client to end
clients.each do |p|
  puts "Waiting for pid #{p} to end"
  continue = true
  while continue
    begin
      Process.kill 0, p
      sleep 1
    rescue Errno::ESRCH
      continue = false
    end
  end
end

puts "Master: Attempting to kill server (#{pid})"
Process.kill 'TERM', pid
