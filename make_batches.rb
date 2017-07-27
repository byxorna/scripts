#!/usr/bin/env ruby
# cat in a file of records (like asset tags), and breaks into batches
# echo -e "1\n2\n3\n4\n5\n6"|./make_batches.rb -b 10,20,50,60 --no-exclusive
# ./make_batches.rb -b 1,5,20,50,100 -x <(collins f web- -S allocated)
require 'optparse'
@params = {
  buckets: [1,5,20,50,100],
  exclusive: true,
  output: nil,
}
OptionParser.new do |opt|
  opt.on('-b','--buckets BUCKETS',Array,'Comma separated list of buckets to divide assets into') {|x| x.map(&:to_f) }
  opt.on('-o','--output-template TEMPLATEFILE',String,'Where to write buckets back out. Will be suffixed with each bucket') {|x| @params[:output] = x }
  opt.on('-x','--[no-]exclusive','Only allow a record to exist in one bucket. Defaults to on') {|x| @params[:exclusive] = x }
  opt.on('-h','--help','Show help'){ puts opt ; exit 0 }
end.parse!

all_entries = ARGF.each_entry.to_a #.map{|x| x.split(/\s+/)[0] }
remaining = all_entries.shuffle
@params[:buckets].sort.each_with_index do |batchsize,i|
  nrecords = (batchsize/100.0*all_entries.length).to_i
  records = remaining.take(nrecords)
  #$stderr.puts "#{remaining.length} * #{batchsize}% = #{records.length} selected"
  $stderr.puts "Bucket #{i}: #{batchsize}% * #{remaining.length} = #{records.length} records"
  records.sort.each {|r| puts r.strip}
  unless @params[:output].nil?
    File.open(@params[:output] + ".#{i}", 'w') do |f|
      records.sort.each {|r| f.puts r.strip }
    end
  end
  remaining = remaining.reject{|x| records.include? x } if @params[:exclusive]
  $stderr.puts "#{remaining.length} records remaining"
end
