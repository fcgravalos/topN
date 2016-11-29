require 'benchmark'
require File.expand_path 'topn_file_processor.rb'

if __FILE__ == $0

  filename = File.expand_path(ARGV[0])
  n = ARGV[1].to_i

  initial_memory = `ps -o rss= -p #{Process.pid}`.to_i

  top = []
  time = Benchmark.realtime{
    top = TopNFileProcessor.process_topn_file(filename)
  }

  puts "*** Top N numbers ***"
  puts top.sort.reverse[0...n]
  puts "*********************"

  puts "Time spent: #{time} s."

  final_memory = `ps -o rss= -p #{Process.pid}`.to_i
  puts "Memory Usage: #{(final_memory - initial_memory)/1024.0 } MB."
end