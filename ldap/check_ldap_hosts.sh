export IFS='
';
for i in `netstat -an | sed -E 's/[[:space:]]+/ /g' | grep '[\.:]389 ' | fgrep ESTABLISHED | cut -d ' ' -f 5 | cut -f 1 -d ':'`; do
    O1=`echo ${i} | cut -f 1-3 -d '.'`
#    echo ${O1}
    O4=`echo ${i} | cut -f 4 -d '.'`
#    echo ${O4}
    printf "%s.%03d\n"  ${O1}  ${O4}
done | sort -n | uniq -c
