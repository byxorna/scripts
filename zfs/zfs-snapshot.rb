#!/usr/bin/ruby

require 'optparse'
require 'logger'

@options = {
  :keep_days => 7,
  :prefix => "snap",
  :suffix => "%s",
  :module => "snapshot",
  :zfs => "/usr/bin/zfs",
  :mode => :snapshot,
  :dry_run => false
}

def log level,m
  if @log
    @log.send(level, m)
  else
    puts m
  end
end


parser = OptionParser.new do |opts|
  opts.separator "Modes:"
  opts.on('-x','--expire FS',"Expires snapshots instead of taking snapshots") {|v| @options[:fs] = v ; @options[:mode] = :expire}
  opts.on('-s','--snapshot FS',"Snapshots filesystem FS (See `zfs list`. This is default)") {|v| @options[:fs] = v ; @options[:mode] = :snapshot }
  opts.separator ""
  opts.separator "Options:"
  opts.on('-k','--keep DAYS',Integer,"Number of days to keep the snapshot (Default: #{@options[:keep_days]})") {|v| @options[:keep_days] = v}
  opts.on('-p','--prefix PREFIX',"Prefix of snapshot (i.e. weekly, daily) (Default: #{@options[:prefix]})") {|v| @options[:prefix] = v}
  opts.on('-S','--suffix SUFFIX',"Suffix of snapshot (i.e. %s, %Y-%m-%d) (Default: #{@options[:suffix]})") {|v| @options[:suffix] = v}
  opts.on('-l','--log LOGFILE',"Where to log (Default: stdout)") {|v| @options[:logfile] = v}
  opts.on('-d','--dryrun',"Dont actually do anything") {|v| @options[:dry_run] = true}
  opts.on('-r','--recursive',"Create snapshots recursively") {@options[:recursive] = true}
  opts.on('-h','--help',"Show help") { puts opts ; exit 0 }
end
parser.parse!

abort "Requires filesystem to snapshot! See --filesystem.\n#{parser.to_s}" if @options[:fs].nil?

@log = Logger.new(@options[:logfile]) if @options[:logfile]

def run_command(cmd)
  unless @options[:dry_run]
    log :debug, "Running: #{cmd}"
    res = `#{cmd}`
    #log :debug, res
    unless $?.success?
      log :error, "Error while running #{cmd}!"
      [false,res]
    else
      [true,res]
    end
  else
    log :info, "Skipped running: #{cmd}"
    [true,""]
  end
end

def snapshot(snapname,expire_at)
  log :info, "Creating snapshot #{@options[:fs]}@#{snapname}"
  command = "#{@options[:zfs]} snapshot #{@options[:recursive] ? '-r ' : ' ' }-o '#{@options[:module]}:managed=true' -o '#{@options[:module]}:expireafter=#{expire_at.strftime('%s')}' '#{@options[:fs]}@#{snapname}'"
  success,output = run_command(command)
  log :error, "Unable to take snapshot!" unless success
  log :info, "Snapshot created: #{@options[:fs]}@#{snapname}" if success
  success
end

def expire
  ts = Time.now
  log :info, "Querying for snapshots to expire as of #{ts}"
  find_attrs_command = "#{@options[:zfs]} list -rHt snapshot -o #{@options[:module]}:managed,#{@options[:module]}:expireafter,space #{@options[:fs]}"
  success,output = run_command(find_attrs_command)
  unless success
    log :error, "Unable to query for snapshots! Aborting expire"
    exit 2
  end
  eligible_snaps = output.lines.map do |l|
    fields = l.split(/\s+/)
    # we only want to work on snaps with module:managed=true
    if fields[0] != "true"
      # #{@options[:module]}:managed,#{@options[:module]}:expireafter,name,avail,used,used‐snap,usedds,usedrefreserv,usedchild -t filesystem,volume
      expiration = Time.at(fields[1].to_i)
      log :debug, "Found managed snapshot: #{fields[2]} with expiration after: #{fields[1]} (#{expiration})"
      { name: fields[2], expiry: expiration }
    else
      nil
    end
  end.compact!

  snaps_to_destroy = eligible_snaps.select {|s| s.expiration < ts }
  unless snaps_to_destroy.empty?
    log :info, "Found #{snaps_to_destroy.length} snapshots to destroy:"
    snaps_to_destroy.each {|s| log :info, " - #{s[:name]}"}
    # we want to return true only if all destroys succeeded
    snaps_to_destroy.all? do |s|
      destroy_cmd = "#{@options[:zfs]} destroy '#{s[:name]}'"
      success,output = run_command(destroy_cmd)
      log :warn, "Destroyed #{s[:name]}" if success
      log :error, "Unable to destroy #{s[:name]}" unless success
      success
    end
  else
    log :info, "No snapshots eligible for pruning found"
    true
  end

end


case @options[:mode]
when :expire
  exit (expire ? 0 : 1)
when :snapshot
  ts = Time.now
  snapname = "#{ts.strftime(@options[:prefix])}#{ts.strftime(@options[:suffix])}"
  expire_at = ts + (86400*@options[:keep_days])
  log :info, "Snapshotting #{@options[:fs]} as #{snapname}"
  log :debug, "Will expire in #{@options[:keep_days]} (#{expire_at.to_s})"
  s = snapshot(snapname,expire_at)
  exit (s ? 0 : 1)
else
  log :error, "Unexpected mode #{@options[:mode]}"
  puts parser
  exit 1
end




