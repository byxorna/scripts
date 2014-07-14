#!/usr/bin/env tumblr_ruby
# stands for collins-log
# looks at logs on assets

# TODO: implement -f --follow polling
# TODO: implement filtering severities
# TODO: add options to sort ascending or descending on date
# TODO: implement searching logs (is this really useful?)
# TODO: add duplicate line detection and compression (...)

require 'collins_auth'
require 'yaml'
require 'optparse'
require 'colorize'

log_levels = Collins::Api::Logging::Severity.constants.map(&:to_s)

@options = {
  :tags => [],
  :show_all => false,
  :severities => [],
  :sev_colors => {
    'EMERGENCY'     => {:color => :red, :background => :light_blue},
    'ALERT'         => {:color => :red},
    'CRITICAL'      => {:color => :black, :background => :red},
    'ERROR'         => {:color => :red},
    'WARNING'       => {:color => :yellow},
    'NOTICE'        => {},
    'INFORMATIONAL' => {:color => :green},
    'DEBUG'         => {:color => :blue},
    'NOTE'          => {:color => :light_cyan},
  },
}
search_opts = {
  :size => 20,
  :filter => nil,
}

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on('-a','--all',"Show logs from ALL assets") {|v| @options[:show_all] = true}
  opts.on('-n','--number LINES',Integer,"Show the last LINES log entries. (Default: #{search_opts[:size]})") {|v| search_opts[:size] = v}
  opts.on('-t','--tags TAGS',Array,"Tags to work on, comma separated") {|v| @options[:tags] = v}
  opts.on('-s','--severity SEVERITY[,...]',Array,"Log severities to return (Defaults to all). Use !SEVERITY to exclude one.") {|v| @options[:severities] = v.map(&:upcase) }
  #opts.on('-i','--interleave',"Interleave all log entries (Default: groups by asset)") {|v| options[:interleave] = true}
  opts.on('-h','--help',"Help") {puts opts ; exit 0}
  opts.separator ""
  opts.separator <<_EOE_
Examples:
  Show last 20 logs for an asset
    #{$0} -t 001234
  Show last 100 logs for an asset
    #{$0} -t 001234 -n100
  Show last 10 logs for 2 assets that are ERROR severity
    #{$0} -t 001234,001235 -n10 -sERROR
  Show last 10 logs all assets that are not note or informational severity
    #{$0} -a -n10 -s'!informational,!note'
  Show last 10 logs for all web nodes that are provisioned having verification in the message
    cf -S provisioned -n webnode\$ | #{$0} -n10 -s debug | grep -i verification
_EOE_
end.parse!


abort "Log severities #{@options[:severities].join(',')} are invalid! Use one of #{log_levels.join(', ')}" unless @options[:severities].all? {|l| Collins::Api::Logging::Severity.valid?(l.tr('!','')) }
search_opts[:filter] = @options[:severities].join(';')

if @options[:tags].empty? and not @options[:show_all]
  # read tags from stdin. first field on the line is the tag
  input = $stdin.readlines
  @options[:tags] = input.map{|l| l.split(/\s+/)[0] rescue nil}.compact.uniq
end

abort "You need to give me some assets to look at; see --help" if @options[:tags].empty? and not @options[:show_all]

begin
  @collins = Collins::Authenticator.setup_client
rescue => e
  abort "Unable to set up Collins client! #{e.message}"
end

def output_logs(logs)
  # colorize output before computing width of fields
  logs.map! do |l|
    l.TYPE = @options[:sev_colors].has_key?(l.TYPE) ? l.TYPE.colorize(@options[:sev_colors][l.TYPE]) : l.TYPE
    l
  end
  # show newest last
  sorted_logs = logs.sort_by {|l| l.CREATED }
  tag_width = sorted_logs.map{|l| l.ASSET_TAG.length}.max
  sev_width = sorted_logs.map{|l| l.TYPE.length}.max
  time_width = sorted_logs.map{|l| l.CREATED.length}.max
  sorted_logs.each do |l|
    puts "%-#{time_width}s: %-#{sev_width}s %-#{tag_width}s %s" % [l.CREATED, l.TYPE, l.ASSET_TAG, l.MESSAGE]
  end
end

if @options[:tags].empty?
  begin
    logs = @collins.all_logs(search_opts)
  rescue => e
    abort "Unable to fetch logs: #{e.message}"
  end
  output_logs(logs)
else
  # query for logs for each asset
  logs = @options[:tags].flat_map do |t|
    begin
      @collins.logs(t, search_opts)
    rescue => e
      $stderr.puts "Unable to fetch logs for #{t}: #{e.message}"
      []
    end
  end
  output_logs(logs)
end


