filename = File.expand_path(ARGV[0])
lines = ARGV[1].to_i || 10000000
max = ARGV[2].to_i || 1000

File.open(filename, 'w') do |f|
  lines.times do
    f.write("#{Random.rand(max).to_s}\n")
  end
end