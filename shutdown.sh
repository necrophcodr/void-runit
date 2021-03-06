#!/bin/sh
# shutdown - shutdown(8) lookalike for runit

single() {
  runsvchdir single
}

usage() {
  echo "Usage: shutdown [-fF] [-kchPr] time [warning message]" >/dev/stderr; exit 1
}

action=single

while getopts akrhPHfFnct: opt; do
  case "$opt" in
    a|n|H) echo "-$opt is not implemented" >/dev/stderr; exit 1;;
    t) ;;
    f) touch /fastboot;;
    F) touch /forcefsck;;
    k) action=true;;
    c) action=cancel;;
    h|P) action=halt;;
    r) action=reboot;;
    [?]) usage;;
  esac
done
shift $(expr $OPTIND - 1)

[ $# -eq 0 ] && usage

time=$1; shift
message="${*:-system is going down}"

if [ "$action" = "cancel" ]; then
  kill $(cat /run/runit/shutdown.pid)
  echo "${*:-shutdown cancelled}" | wall
  exit
fi

if ! touch /run/runit/shutdown.pid 2>/dev/null; then
  echo "Not enough permissions to execute ${0#*/}"
  exit 1
fi
echo $$ >/run/runit/shutdown.pid

case "$time" in
  now) time=0;;
  +*) time=${time#+};;
  *:*) echo "absolute time is not implemented" >/dev/stderr; exit 1;;
  *) echo "invalid time"; exit 1;;
esac

if [ "$time" -gt 5 ]; then
  echo "$message in $time minutes" | wall
  echo -n "shutdown: sleeping for $time minutes... "
  sleep $(expr '(' "$time" - 5 ')' '*' 60)
  echo
  time=5
fi

if [ "$time" -gt 0 ]; then
  echo "$message in $time minutes" | wall
  touch /etc/nologin
  echo -n "shutdown: sleeping for $time minutes... "
  sleep $(expr "$time" '*' 60)
  echo
  rm /etc/nologin
fi

echo "$message NOW" | wall

$action
