#!/usr/bin/env ruby

# takes % of the lines given on input
require 'optparse'

@params = {
  percent: 1.0, # 0-100
  output_file: :stdout,
}
parser = OptionParser.new do |opt|
  opt.on('-p','--percent PCT',Float,'percent of lines to sample (0.0-100.0)') {|p| @params[:percent] = p} 
  opt.on('-h','--help','show help') { puts opt ; exit 0 }
  opt.on('-o','--output FILE','file to write output to') {|f| @params[:output_file] = f}
end
parser.parse!

unless (@params[:percent].is_a? Float) &&
  (@params[:percent] <= 100.0 || @params[:percent] >= 0.0)
  $stderr.puts "Unsupported value for percent #{@params[:percent]}; try float 0.0->100.0"
  exit 1
end
#ARGF.each_entry{|e| puts e}
entries = ARGF.each_entry.to_a
nrecords = (@params[:percent]/100.0*entries.length).to_i
records = entries.shuffle.take(nrecords)
$stderr.puts "#{records.length} records, #{@params[:percent]}% = #{nrecords}"
records.sort.each {|r| puts r.strip}
