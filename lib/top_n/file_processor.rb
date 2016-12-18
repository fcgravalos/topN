module TopN
  class FileProcessor
    attr_accessor :filename
    attr_accessor :chunk_size
    attr_accessor :output_dir
    attr_accessor :output_prefix

    def initialize(filename, split_opts = {})
      split_opts.merge!(
        chunk_size: '128k',
        output_dir: File.dirname(filename),
        output_prefix: 'splitted'
      )

      @filename = filename
      @chunk_size = split_opts[:chunk_size]
      @output_dir = split_opts[:output_dir]
      @output_prefix = split_opts[:output_prefix]
    end

    def split_file
      system("split -b #{chunk_size} #{filename} #{output_dir}/#{output_prefix}")
      Dir.glob("#{output_dir}/#{output_prefix}*")
    end
  end
end