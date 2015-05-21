require 'tempfile'

module SimpleStatsStore
  class FileDump
    def initialize(dir)
      @dir = dir
    end

    def files_contents
      contents = []
      Dir["#{@dir}/*"].each do |f|
        begin
          data = File.open(f, 'r').read
          if /\n---\n$/.match(data)
            contents << data
            File.delete(f)
          end
        catch Error::ENOENT
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
      while File.exists?(File.expand_path("sss-#{$$}-#{Time.new.to_i}-#{i}.stats", @dir))
        i += 1
      end
      File.open(File.expand_path("sss-#{$$}-#{Time.new.to_i}-#{i}.stats", @dir), 'w') do |f|
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
