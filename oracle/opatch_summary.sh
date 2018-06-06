#!/bin/bash
# Script to give a summary view of patches applied to an Oracle Home.
# Similar to "opatch lspatch" but also shows the applied date and
# for one-offs, fetches the patch description from
# $ORACLE_HOME/inventory/oneoffs.  Currently shows opatch version,
# oracle_home location and then the patch information.
#
# Author: Wayne Adams
#         Wayne Adams Consulting
#         www.wayneadamsconsulting.com
#
# Accepts one argument, --csv, which removes the opatch/ohome info
# and the field descriptions/titles and adds a field seperator.
# Useful if you want to feed this data into another script.

# Process any command line args
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --csv)
            CSVFORMAT="true"
            ;;
        *)
            echo "Invalid argument: $key"
            echo "Usage: $0 [--csv]"
            exit 1
            ;;
    esac
    shift
done

if [[ ! -x $ORACLE_HOME/OPatch/opatch ]]; then
    echo "Error: $ORACLE_HOME/OPatch/opatch does not exist or is not executable!"
    exit 1
fi

# Output delimiter used when --csv is specified
CSVDELIM="|"

OPATCH_INFO_LINE_PROC="false"

IFS="|"

# Pipe the output of opatch lsinventory to perl to parse out the
# opatch version, oracle_home location, patch#,
# applied date, and bug description (if provided by opatch)
# Note: this perl one-liner is probably needlessly complex but was an
# interesting exercise (probably shouldn't be a one-liner) and I wanted
# to run opatch only once.
# $ORACLE_HOME/OPatch/opatch lsinventory |perl -0777 -nle 'print "$1 | $2 \n" while m/Oracle Home\s+:\s([\w\/\.]+)\s+Central.*\s+from.*\s+OPatch version\s+:\s([\d\.]+)/mg; print "$1|$2|$5\n" while m/Patch\s+(\d+)\s+:\s+applied on (\w+\s\w+\s\d+\s\d+:\d+:\d+\s\w+\s\d+)\s+(Unique.*)*\s+(Patch description:\s+"(.*)")*/gm' |while read pnum pdate pdesc

LS_OUT=`mktemp lsinv.XXX`
# echo "LS_OUT: '${LS_OUT}'"

${ORACLE_HOME}/OPatch/opatch lsinventory >${LS_OUT} 2>&1
LS_OFILE=`grep '^Lsinventory Output file location' ${LS_OUT} | cut -f 2 -d ':' | tr -d ' '`
# echo "LS_OFILE: '${LS_OFILE}'"

cat ${LS_OUT} | perl -0777 -nle 'print "$1 | $2 \n" while m/Oracle Home\s+:\s([\w\/\.-]+)\s+Central.*\s+from.*\s+OPatch version\s+:\s([\d\.]+)/mg' | while read ohome opver
do
    if [[ $CSVFORMAT != "true" ]]; then
        echo "Opatch Version: $opver  Oracle Home: $ohome"
    fi
done

PROD_NUM=`cat ${LS_OFILE} | perl -0777 -nle 'print "$1\n" while m/Installed Top-level.*\((\d+)\):/msg'`
# echo "PROD_NUM: '${PROD_NUM}'"

PRODS=`cat ${LS_OFILE} | perl -0777 -nle 'print "$1\n" while m/Installed Top-level.*\(\d+\):\s+(.*)/msg'`
echo $PRODS | head -${PROD_NUM} | perl -0777 -nle 'print "$1 | $2 \n" while m/([A-Za-z\ ]+[A-Za-z])\s+([\d\.]+)/g' | while read prodname prodver
do
    if [[ $CSVFORMAT != "true" ]]; then
        printf "Product: %-30s Version: %20s\n" $prodname $prodver
    fi
done

cat ${LS_OUT} | perl -0777 -nle 'print "$1|$2|$5\n" while m/Patch\s+(\d+)\s+:\s+applied on (\w+\s\w+\s\d+\s\d+:\d+:\d+\s\w+\s\d+)\s+(Unique.*)*\s+(Patch description:\s+"(.*)")*/gm' |while read pnum pdate pdesc
do
    if [[ $OPATCH_INFO_LINE_PROC = "false" ]]; then
        OPATCH_INFO_LINE_PROC="true"
        if [[ $CSVFORMAT != "true" ]]; then
            echo "Patch#     Applied Date                   Description"
            echo "-------------------------------------------------------------------------------"
        fi
    fi

    export pnum

    # If no patch description from opatch, fetch it from $ORACLE_HOME/inventory/oneoffs
    if [[ -z $pdesc || $pdesc = "One-off" ]]; then
        export PRE_11g_ONEOFF_INV_FILE=$ORACLE_HOME/inventory/oneoffs/$pnum/etc/config/inventory
        export POST_11g_ONEOFF_INV_FILE=$ORACLE_HOME/inventory/oneoffs/$pnum/etc/config/inventory.xml

        bug_desc=$((if [[ -f $POST_11g_ONEOFF_INV_FILE ]]; then cat $POST_11g_ONEOFF_INV_FILE; else cat $PRE_11g_ONEOFF_INV_FILE; fi) |perl -nle 'print "$1" while m/bug number="$ENV{pnum}" description="(.*)"/g')

        # If no matching bug description in the oneoff inventory.xml,
        # then say so.  The patch is probably some bundle of some sort.
        # We could try to fetch every bug description in the patch, but that would
        # probably make the output line very long and harder to understand, so I
        # didn't want that here.
        if [[ -z $bug_desc ]]; then
            bug_desc="(no description for matching bug# found)"
        fi

        pdesc="  ONEOFF=> $bug_desc"
    fi
    if [[ $CSVFORMAT = "true" ]]; then
        echo "${pnum}${CSVDELIM}${pdate}${CSVDELIM}${pdesc}"
    else
        echo "$pnum   $pdate   $pdesc"
    fi
done;
rm ${LS_OUT}
