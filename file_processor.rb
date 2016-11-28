class TopNFileProcessor
    attr_accessor :filename

    def initialize(filename)
        @filename = filename
    end

    def split_file(chunk_size = '4m', output_prefix = 'splitted')
        dir = File.dirname(filename)
        system("split -b #{chunk_size} #{filename} #{dir}/#{output_prefix}")
        Dir.glob("#{dir}/#{output_prefix}*")
    end

    def self.process_topn_file(filename)
      tp = TopNFileProcessor.new(filename)
      tp.map
    end
end