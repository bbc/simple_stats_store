module SimpleStatsStore
  class NilDump
    def each(&block)
      [].each(&block)
    end
  end
end
