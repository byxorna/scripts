#!/bin/bash
# Ghetto script to kill a command after a timeout
# Written Nov 14 2013

timeout=10s
echo "Executing $@ with timeout $timeout"
$@ &
child_pid=$!
echo "spawned $child_pid"

( sleep $timeout && ps -p $child_pid && kill -9 $child_pid ) >/dev/null 2>&1 &
reaper_pid=$!
echo "reaper pid $reaper_pid"
ps
echo "waiting on $child_pid"
wait $child_pid
child_return=$?
echo "child returned $child_return"

case $child_return in
[0-3])
  echo "child exited successfully"
  exit $child_return
  ;;
*)
  echo "Child was forcibly killed, probably hung"
  exit $child_return
  ;;
esac

