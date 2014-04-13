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
  opts.on('-h','--help',"Show help") { puts opts ; exit 0 }
end
parser.parse!

abort "Requires filesystem to snapshot! See --filesystem.\n#{parser.to_s}" if @options[:fs].nil?

@log = Logger.new(@options[:logfile] || STDOUT)

def run_command(cmd)
  unless @options[:dry_run]
    @log.debug "Running: #{cmd}"
    res = `#{cmd}`
    @log.debug res
    unless $?.success?
      @log.error "Error while running #{cmd}!"
      false
    else
      true
    end
  else
    @log.info "Skipped running: #{cmd}"
    true
  end
end

def snapshot(snapname,expire_at)
  @log.info "Creating snapshot #{@options[:fs]}@#{snapname}"
  command = "#{@options[:zfs]} snapshot -o '#{@options[:module]}:expireafter=#{expire_at.strftime('%s')}' '#{@options[:fs]}@#{snapname}'"
  success = run_command(command)
  @log.error "Unable to take snapshot!" unless success
  @log.info "Snapshot created: #{@options[:fs]}@#{snapname}" if success
  success
end

def expire
  ts = Time.now
  @log.info "Querying for snapshots to expire as of #{ts}"
  find_attrs_command = "#{@options[:zfs]} get -rpHs local all #{@options[:fs]}"
  run_command(find_attrs_command)

end


case @options[:mode]
when :expire
  exit (expire ? 0 : 1)
when :snapshot
  ts = Time.now
  snapname = "#{ts.strftime(@options[:prefix])}#{ts.strftime(@options[:suffix])}"
  expire_at = ts + (86400*@options[:keep_days])
  @log.info "Snapshotting #{@options[:fs]} as #{snapname}"
  @log.debug "Will expire in #{@options[:keep_days]} (#{expire_at.to_s})"
  s = snapshot(snapname,expire_at)
  exit (s ? 0 : 1)
else
  @log.error "Unexpected mode #{@options[:mode]}"
  puts parser
  exit 1
end




