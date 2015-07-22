export IFS='
';
for i in `netstat -an | sed -E 's/[[:space:]]+/ /g' | grep '[\.:]389 ' | fgrep ESTABLISHED | cut -d ' ' -f 5 | cut -f 1 -d ':'`; do
    O1=`echo ${i} | cut -f 1 -d '.'`
    O2=`echo ${i} | cut -f 2 -d '.'`
    O3=`echo ${i} | cut -f 3 -d '.'`
    O4=`echo ${i} | cut -f 4 -d '.'`
    printf "%03d.%03d.%03d.%03d\n"  ${O1} ${O2} ${O3} ${O4}
done | sort -n | uniq -c
