require 'benchmark'
require 'thread'
require 'fileutils'

def split_file(filename, chunk_size=4)
  system("split -b #{chunk_size}m #{filename} splitted")
  Dir.glob("splitted*")
end

def process_chunk(chunk)
  top = []
  File.foreach(chunk) do |line|
      top << line.strip.to_i
  end
  top
end

if __FILE__ == $0
  filename = File.expand_path(ARGV[0])
  n =  ARGV[1].to_i
    
  top = []
  semaphore = Mutex.new
 
  initial_memory = `ps -o rss= -p #{Process.pid}`.to_i

  time = Benchmark.realtime {
    splitted_files = split_file(filename)
    splitted_files.each do |chunk|
      thread = Thread.new {
        semaphore.synchronize {
          top = top | process_chunk(chunk)
          FileUtils.rm_f chunk 
        }
      }
      thread.join
    end
  }
  puts "*** Top N numbers ***"
  puts top.sort.reverse[0...n]
  puts "*********************"
  
  puts "Time spent: #{time} s."

  final_memory = `ps -o rss= -p #{Process.pid}`.to_i
  puts "Memory Usage: #{(final_memory - initial_memory)/1024.0 } MB."
end