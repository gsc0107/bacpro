#!/bin/bash

source pap_common.sh

min_reads=4000000; 
html_format=0;
papdir=""

# ----------------------------------------------------------------------
# Function: usage
# Purpose:  Print usage text
# ----------------------------------------------------------------------
function usage
{
cat << EOF
usage: $0 < -o id | -d dir > [ -m int ] [ -p directory_name ]

Get FASTQC summary statistics 

OPTIONS:
	-h	Show this message
	-m	Number - minimum number of reads expected
        -p      QC directory 
	-t	Format output in HTML
EOF
}

# ----------------------------------------------------------------------
# Main program
# ----------------------------------------------------------------------

# Loop through command line options
while getopts d:ehm:o:p:t OPTION
do
     case $OPTION in
         h) usage ; exit 1 ;;
         m) min_reads=$OPTARG;;
	 p) papdir=$OPTARG;;
         t) html_format=1;;
     esac
done

tempfile=`mktemp ~/log.XXXXX`

if [ ${html_format} -eq 1 ] ; then
    echo "<html>" >> ${tempfile}
    echo "<body>" >> ${tempfile}
    echo "<h1>FASTQC summary statistics</h1>" >> ${tempfile}
    echo "<table border=1 cellspacing=0>" >> ${tempfile}
    echo "<tr><th>Filename</th><th>Reads</th><th>Q30to</th><th>Over-represented sequence</th></tr>" >> ${tempfile}
else
    echo "FastQC summary statistics\n" > ${tempfile}
    echo "||Filename||Reads||Q30to||Over-represented sequence||\n" >> ${tempfile};
fi

tempfilelist=`mktemp ~/filelist.XXXXX`
for i in ${papdir}/*/*/Stats/*/fastqc_data.txt
do
    echo ${i} >> ${tempfilelist}
done

for i in `cat ${tempfilelist}`
do

    if [ ${html_format} -eq 1 ] ; then
        perl fastqc_parse.pl -fastqc $i -minreads ${min_reads} -q 28 -html >> ${tempfile}
    else
        perl fastqc_parse.pl -fastqc $i -minreads ${min_reads} -q 28 >> ${tempfile}
    fi
done

rm ${tempfilelist}

if [ ${html_format} -eq 1 ] ; then
    echo "</table>" >> ${tempfile}
    echo "</body>" >> ${tempfile}
    echo "</html>" >> ${tempfile}
fi

# remove the temp file
cat ${tempfile}
rm -f ${tempfile}


