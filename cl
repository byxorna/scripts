#!/usr/bin/env tumblr_ruby
# stands for collins-log
# looks at logs on assets

# TODO: implement -f --follow polling
# TODO: implement filtering severities
# TODO: add options to sort ascending or descending on date

require 'collins_auth'
require 'yaml'
require 'optparse'

#log_levels = Collins::Api::Logging::Severity.constants.map(&:to_s)

options = {
  :tags => [],
  #:interleave => false,
  :size => 20,
  #:log_level => 'NOTE'
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on('-a','--all',"Show logs from ALL assets") {|v| options[:show_all] = true}
  opts.on('-n','--number LINES',Integer,"Show the last LINES log entries. (Default: #{options[:size]})") {|v| options[:size] = v}
  opts.on('-t','--tags TAGS',Array,"Tags to work on, comma separated") {|v| options[:tags] = v}
  #opts.on('-i','--interleave',"Interleave all log entries (Default: groups by asset)") {|v| options[:interleave] = true}
  opts.on('-h','--help',"Help") {puts opts ; exit 0}
end.parse!


#abort "Log level #{options[:log_level]} is invalid! Use one of #{log_levels.join(', ')}" unless Collins::Api::Logging::Severity.valid?(options[:log_level])

if options[:tags].empty? and not options[:show_all]
  # read tags from stdin. first field on the line is the tag
  input = $stdin.readlines
  options[:tags] = input.map{|l| l.split(/\s+/)[0] rescue nil}.compact.uniq
end

abort "You need to give me some assets to look at; see --help" if options[:tags].empty? and not options[:show_all]

begin
  @collins = Collins::Authenticator.setup_client
rescue => e
  abort "Unable to set up Collins client! #{e.message}"
end

def output_logs(logs,options)
  # show newest last
  sorted_logs = logs.sort_by {|l| l.CREATED }
  tag_width = sorted_logs.map{|l| l.ASSET_TAG.length}.max
  sev_width = sorted_logs.map{|l| l.TYPE.length}.max
  time_width = sorted_logs.map{|l| l.CREATED.length}.max
  sorted_logs.each do |l|
    puts "%-#{time_width}s: %-#{sev_width}s %-#{tag_width}s %s" % [l.CREATED, l.TYPE, l.ASSET_TAG, l.MESSAGE]
  end
end

if options[:tags].empty?
  logs = @collins.all_logs(:size => options[:size])
  output_logs(logs,options)
else
  # query for logs for each asset
  logs = options[:tags].flat_map do |t|
    begin
      @collins.logs(t, :size => options[:size])
    rescue => e
      $stderr.puts "Unable to fetch logs for #{t}: #{e.message}"
      []
    end
  end
  output_logs(logs,options)
end


