filename = File.expand_path(ARGV[0])

File.open(filename, 'w') do |f|
    for i in 1..10000000 do
        f.write("#{Random.rand(1000).to_s}\n")
    end
end