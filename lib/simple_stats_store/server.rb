module SimpleStatsStore
  class Server
    def initialize(options)
      @data_dump = options[:data_dump]
      @models = options[:models]
      @name = options[:name] || $0
    end

    def scan
      @data_dump.each do |stats|
        lines = stats.split("\n")
        if lines.shift != '---' or lines.pop != '---'
          puts "Corrupt statistics"
          return false
        end

        model = lines.shift.strip
        data = {}
        lines.each do |l|
          k, v = l.split(/:/, 2)
          data[k.strip.to_sym] = v.strip
        end

        @models[model.to_sym].create(data)
      end
    end

    def run(&block)
      Process.fork do
        $0 = @name
        loop do
          self.scan
          yield if block_given?
          sleep 0.1
        end
      end
    end
  end
end
