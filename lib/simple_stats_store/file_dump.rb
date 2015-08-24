require 'tempfile'

module SimpleStatsStore
  class FileDump
    def initialize(dir)
      @dir = dir
    end

    def files_contents
      contents = []
      Dir["#{@dir}/**/*.stats"].each do |f|
        begin
          data = File.open(f, 'r').read
          if /\n---\n$/.match(data)
            contents << data
            File.delete(f)
          end
        rescue Errno::ENOENT
          puts "Failed to open file #{f}"
        end
      end
      contents
    end

    def each(&block)
      files_contents.each &block
    end

    def write(model, data)
      i = 0
      subdir = File.expand_path(model, @dir)
      Dir.mkdir(subdir) if ! Dir.exists?(subdir)
      while File.exists?(File.expand_path("sss-#{$$}-#{Time.new.to_i}-#{i}.stats", subdir))
        i += 1
      end
      File.open(File.expand_path("sss-#{$$}-#{Time.new.to_i}-#{i}.stats", subdir), 'w') do |f|
        f.puts "---"
        f.puts model
        data.each do |key, value|
          f.puts "#{key.to_s}: #{value}"
        end
        f.puts "---"
      end
    end
  end
end
