require 'spec_helper'
require 'simple_stats_store/server'
require 'simple_stats_store/nil_dump'
require 'simple_stats_store/file_dump'
require 'tempfile'
require 'sqlite3'
require 'active_record'

RSpec.describe 'server' do
  describe '#initialise' do
    it 'creates a SimpleStatsStoreStore::Server instance' do
      expect(SimpleStatsStore::Server.new(
        data_dump: SimpleStatsStore::NilDump.new,
        models: {}
      )).to be_a(SimpleStatsStore::Server)
    end

    it 'sets the data_dump correctly' do
      dump = SimpleStatsStore::NilDump.new
      expect(SimpleStatsStore::Server.new(
        data_dump: dump,
        models: {}
      ).instance_variable_get(:@data_dump)).to eq dump
    end
  end

  describe '#scan' do
    it 'uploads a correctly formed data item' do
      ActiveRecord::Base.establish_connection(
        adapter: :sqlite3,
        database: Tempfile.new(['stats', '.sql']).path
      )
      ActiveRecord::Schema.define do
        create_table :stats do |table|
          table.column :timestamp, :string
          table.column :x, :float
          table.column :y, :float
        end
      end

      class Stats < ActiveRecord::Base
      end

      Dir.mktmpdir do |dir|
        File.open(File.expand_path('stat1.data', dir), 'w') do |stat|
          stat.puts "---"
          stat.puts "stats"
          stat.puts "timestamp: 2015-04-30 15:47:32.123"
          stat.puts "x: 1"
          stat.puts "y: 3"
          stat.puts "---"
        end
        expect { SimpleStatsStore::Server.new(
          data_dump: SimpleStatsStore::FileDump.new(dir),
          models: {stats: Object.const_get('Stats')}
        ).scan }.to change(Stats, :count).by(1)
      end
    end
  end
end
