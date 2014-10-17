#!/usr/bin/env ruby
require 'date'
require 'optparse'
# parses nginx access logs and creates histograms
# very rough shape.
# Example:  head -n 180000 access.log |egrep '172.16.120.171|172.16.120.176' |ruby histo.rb -b 60

@bucket_width_s = 60
@max_y_scale = nil
OptionParser.new do |opts|
  opts.on('-b','--bucket-size SECONDS',Integer,"Group events into buckets of size SECONDS (Default #{@bucket_width_s})") {|v| @bucket_width_s = v}
  opts.on('-y','--max-y-value MAX',Integer,"Group events into buckets of size SECONDS (Default #{@max_y_scale})") {|v| @max_y_scale = v}
end.parse!


#elements = ARGF.each_line.map do |l|
#  #fields = l.split(" ")
#  #[172.16.118.8:8080] 172.16.120.171 [16/Oct/2014:04:39:29 -0400] 200 "GET /api/asset/killswitch HTTP/1.1" 1007 "-" "-" "-" "127.0.0.1:8081:200"
#  #host,client,time1,time_tz,resp,verb,url,proto,size = fields
#  #time_str = time1[1..-1] + " " + time_tz[0...-1]
#  DateTime.strptime(l.split(" ")[2,2].join(" ")[1...-1],"%d/%b/%Y:%H:%M:%S %z")
#  #time = DateTime.strptime(time_str,"%d/%b/%Y:%H:%M:%S %z")
#  #verb = verb[1..-1]
#  #{
#  #  :verb => verb,
#  #  :time => time,
#  #  :host => host,
#  #  :client => client,
#  #  :url => url,
#  #  :size => size
#  #}
#end

#lets bucket based on flags
#TODO have a max width (term width?) and either take max or avg of merged buckets

elements = ARGF.each_line.map do |l|
  DateTime.strptime(l.split(" ")[2,2].join(" ")[1...-1],"%d/%b/%Y:%H:%M:%S %z")
end
bucket_start = elements.first.to_time
bucket_end = bucket_start + @bucket_width_s
puts "Creating histogram with buckets of #{@bucket_width_s} seconds"
# create a sparse histogram
histo = elements.reduce([0]) do |buckets,entry|
  # check if this guy falls into the bucket
  t = entry.to_time
  # seek forward looking for where he should go, blanking buckets that are empty
  while !(t < bucket_end && t >= bucket_start)
    bucket_start = bucket_end
    bucket_end = bucket_end + @bucket_width_s
    buckets << 0
  end
  buckets[buckets.length-1] = (buckets.last || 0)+1
  buckets
end


# display histogram like a fucking dot matrix printer
display_width = 80
histo_max_height = 20
# we will page by display_width if histo width is larger than our display
total_pages = [(histo.length/display_width.to_f).ceil,1].max
matrix = (0...histo_max_height).map{|h| Array.new(histo.length," ")}
max_v = @max_y_scale || histo.max
puts "Showing histogram #{histo.length}x#{histo_max_height}, paged into #{total_pages} pages, max val #{max_v}"
histo.each_with_index do |v,x|
  normalized_v = (v.to_f/max_v*histo_max_height).round
  #puts "Was #{v}, now #{normalized_v}"
  #matrix << Array.new(histo_max_height-normalized_v," ") + Array.new(normalized_v,"*")
  (0...normalized_v).each do |h|
    #we set the "pixel" we want on in the matrix
    #matrix[histo_max_height-h-1][x] = "*"
    x = x
    y = histo_max_height-h-1
    #puts "Working on h=#{h} x=#{x} #{histo_max_height-h} #{normalized_v}"
    matrix[y][x] = "*"
  end
end

#generate a y_axis
padding_width = max_v.to_s.length
y_axis = (0...histo_max_height).map do |i|
  case i
  when histo_max_height-1
    "%-#{padding_width}d" % 0
  when 0
    max_v
  else "%-#{padding_width}s" % " "
  end
end

# show the histgram paged by max_width
puts "computed #{total_pages} pages from #{display_width} #{histo.length}"
(0...total_pages).each do |page_i|
  matrix.each_with_index do |row,i|
    r = row[page_i*display_width,display_width]
    puts "#{y_axis[i]} #{r.join}"
  end
  #TODO i know there is a better way to do this with a format string, but i dont remember how
  b_s, b_e = page_i*@bucket_width_s*display_width, (page_i+1)*display_width*@bucket_width_s
  t_s = "#{b_s} sec"
  t_e = "#{b_e} sec"
  puts "%s%s%s" % [t_s," "*(display_width-10),t_e]
  puts "page #{page_i+1}: #{b_s} seconds to #{b_e} seconds, requests in #{@bucket_width_s} second buckets"
end




