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

  def process_chunk(chunk)
    chunk_top = []
    File.foreach(chunk) do |line|
      chunk_top << line.strip.to_i
    end
    chunk_top
  end

  def self.process_topn_file(filename)
    top = []
    semaphore = Mutex.new

    tp = TopNFileProcessor.new(filename)

    tp.split_file.each do |chunk|
      thread = Thread.new {
        semaphore.synchronize {
          top = top | tp.process_chunk(chunk)
          FileUtils.rm_f chunk
        }
      }
      thread.join
    end
    top
  end
end