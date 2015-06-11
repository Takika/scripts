export IFS='
';
for i in `netstat -veetpnau | sed -E 's/[[:space:]]+/ /g' | grep '[\.:]389 ' | fgrep '/' | cut -d ' ' -f 9 | cut -f 1 -d '/'`; do
    ps ax | sed -r 's/^\s+//g' | grep "^${i}\s" | fgrep -v fgrep;
    done | sed -r 's/\s+/ /g' | cut -d ' ' -f 5- | cut -d ' ' -f 1 | sort | uniq -c
    