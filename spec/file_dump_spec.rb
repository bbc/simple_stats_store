require 'spec_helper'
require 'simple_stats_store/file_dump'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'SimpleStatsStore::FileDump' do
  describe '#initialise' do
    it 'creates a SimpleStatsStoreStore::FileDump instance' do
      Dir.mktmpdir do |dir|
        expect(SimpleStatsStore::FileDump.new(dir)).to be_a(SimpleStatsStore::FileDump)
      end
    end
  end

  describe '#files_contents' do
    it 'returns the content of a file in the given directory' do
      Dir.mktmpdir do |dir|
        Dir.mkdir(File.expand_path('stats', dir))
        File.open(File.expand_path('stats/file1.stats', dir), 'w') do |f|
          f.puts "---"
          f.puts "Line 1"
          f.puts "Line 2"
          f.puts "---"
        end
        expect(SimpleStatsStore::FileDump.new(dir).files_contents).to match(["---\nLine 1\nLine 2\n---\n"])
      end
    end

    it 'returns the contents of all files in the given directory' do
      Dir.mktmpdir do |dir|
        Dir.mkdir(File.expand_path('stats', dir))
        File.open(File.expand_path('stats/file1.stats', dir), 'w') do |f|
          f.puts "---"
          f.puts "Line 1"
          f.puts "---"
        end
        File.open(File.expand_path('stats/file2.stats', dir), 'w') do |f|
          f.puts "---"
          f.puts "Line 2"
          f.puts "---"
        end
        File.open(File.expand_path('stats/file3.stats', dir), 'w') do |f|
          f.puts "---"
          f.puts "Line 3"
          f.puts "---"
        end
        expect(SimpleStatsStore::FileDump.new(dir).files_contents).to match(["---\nLine 1\n---\n", "---\nLine 2\n---\n", "---\nLine 3\n---\n"])
      end
    end

    it 'does not return an incomplete stats file' do
      Dir.mktmpdir do |dir|
        Dir.mkdir(File.expand_path('stats', dir))
        File.open(File.expand_path('stats/file1.stats', dir), 'w') do |f|
          f.puts "---"
          f.puts "Line 1"
          f.puts "Line 2"
        end
        expect(SimpleStatsStore::FileDump.new(dir).files_contents).to eq []
      end
    end

    it 'returns the contents of only complete files in the given directory' do
      Dir.mktmpdir do |dir|
        Dir.mkdir(File.expand_path('stats', dir))
        File.open(File.expand_path('stats/file1.stats', dir), 'w') do |f|
          f.puts "---"
          f.puts "Line 1"
          f.puts "---"
        end
        File.open(File.expand_path('stats/file2.stats', dir), 'w') do |f|
          f.puts "---"
          f.puts "Line 2"
          f.puts "---"
        end
        File.open(File.expand_path('stats/file3.stats', dir), 'w') do |f|
          f.puts "---"
          f.puts "Line 3"
        end
        expect(SimpleStatsStore::FileDump.new(dir).files_contents).to match(["---\nLine 1\n---\n", "---\nLine 2\n---\n"])
      end
    end

    it 'gets an empty list for no files' do
      Dir.mktmpdir do |dir|
        expect(SimpleStatsStore::FileDump.new(dir).files_contents).to eq []
      end
    end

    it 'deletes file after collecting' do
      Dir.mktmpdir do |dir|
        Dir.mkdir(File.expand_path('stats', dir))
        f = File.open(File.expand_path('stats/file1.stats', dir), 'w')
        f.puts "---"
        f.puts "Line 1"
        f.puts "Line 2"
        f.puts "---"
        f.close
        SimpleStatsStore::FileDump.new(dir).files_contents
        expect(File.exists?(f.path)).to be_falsy
      end
    end

    it 'does not delete an incomplete stats file' do
      Dir.mktmpdir do |dir|
        Dir.mkdir(File.expand_path('stats', dir))
        f = File.open(File.expand_path('stats/file1.stats', dir), 'w')
        f.puts "---"
        f.puts "Line 1"
        f.puts "Line 2"
        f.close
        SimpleStatsStore::FileDump.new(dir).files_contents
        expect(File.exists?(f.path)).to be_truthy
      end
    end
  end

  describe '#write' do
    it 'puts data files in the directory' do
      Dir.mktmpdir do |dir|
        SimpleStatsStore::FileDump.new(dir).write('stats', { key1: 'value 1', key2: 'value 2' })
        SimpleStatsStore::FileDump.new(dir).write('stats', { key1: 'value 3', key2: 'value 4' })
        expect(Dir["#{dir}/**/*.stats"].length).to eq 2
      end
    end

    it 'writes the data to the new file' do
      Dir.mktmpdir do |dir|
        SimpleStatsStore::FileDump.new(dir).write('stats', { key1: 'value 1', key2: 'value 2' })
        File.open(Dir["#{dir}/**/*.stats"][0], 'r') do |file|
          expect(file.read.split("\n")).to match([
            '---',
            'stats',
            'key1: value 1',
            'key2: value 2',
            '---'
          ])
        end
      end
    end

    it 'writes the data to the new file (using symbols for model name)' do
      Dir.mktmpdir do |dir|
        SimpleStatsStore::FileDump.new(dir).write(:stats, { key1: 'value 1', key2: 'value 2' })
        File.open(Dir["#{dir}/**/*.stats"][0], 'r') do |file|
          expect(file.read.split("\n")).to match([
            '---',
            'stats',
            'key1: value 1',
            'key2: value 2',
            '---'
          ])
        end
      end
    end

    it 'writes no more than the maximum number of files per model' do
      Dir.mktmpdir do |dir|
        sss = SimpleStatsStore::FileDump.new(dir, max: 5)
        6.times do
          sss.write(:stats, { key1: 'value 1', key2: 'value 2' })
        end
        expect(Dir["#{dir}/**/*.stats"].length).to eq 5
        6.times do
          sss.write(:stats, { key1: 'value 1', key2: 'value 2' })
          expect(Dir["#{dir}/**/*.stats"].length).to eq 5
        end
      end
    end

    it 'removes oldest file when maximum file number reached' do
      Dir.mktmpdir do |dir|
        sss = SimpleStatsStore::FileDump.new(dir, max: 5)
        5.times do |i|
          sss.write(:stats, { key1: 'value 1', key2: "value :#{i}:" })
        end
        sss.write(:stats, { key1: 'value 1', key2: 'value :5:' })
        File.open(Dir["#{dir}/**/*.stats"][0], 'r') do |file|
          expect(file.read.split("\n")).not_to match([
            '---',
            'stats',
            'key1: value 1',
            'key2: value :0:',
            '---'
          ])
        end
      end
    end

    it 'removes files if there are too many' do
      Dir.mktmpdir do |dir|
        sss = SimpleStatsStore::FileDump.new(dir, max: 10)
        10.times do |i|
          sss.write(:stats, { key1: 'value 1', key2: "value 2" })
        end
        sss2 = SimpleStatsStore::FileDump.new(dir, max: 5)
        sss2.write(:stats, { key1: 'value 1', key2: 'value 2' })
        expect(Dir["#{dir}/**/*.stats"].length).to eq 5
      end
    end
  end
end
