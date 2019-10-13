#!/bin/bash

# Configuration
Target_List_CSV_FILE="list_of_copy_files.csv"
NumOfParallels=$1
SummaryResultCSVFile=$2
SarFile=test_3_sar_
ExecCommand=./test_2_s3ts3_python.py

if [ ! ${NumOfParallels} -gt 0 ]; then
    echo "Invalit Number of Paralles.(NumOfParalles=${NumOfParallels})"
    exit 1
fi

if [ ! -f ${SummaryResultCSVFile} ]; then
    echo "Not found a summary csv file(SummaryResultCSVFile=${SummaryResultCSVFile})"
    exit 1
fi


# Initialize
rows=$(grep -c '' ${Target_List_CSV_FILE})
NumOfsplitLines=$(( rows/NumOfParallels ))


#------------------------
# Functions
#------------------------
function utcserial2date {
    #echo $(date -j -f '%s' ${1} '+%Y/%m/%d %H:%M:%S') #for mac
    echo $(date --date="@${1}" '+%Y/%m/%d %H:%M:%S')  #for linux
}

#------------------------
# Main
#------------------------
# Split Target_List_CSV_FILE
split -a 5 -l ${NumOfsplitLines} ${Target_List_CSV_FILE} "test_3_target_list_"


# Lunch sar command
sar -A -o ${SarFile}${rows}_${NumOfParallels} 1 10000000 >/dev/null 2>&1 &
SAR_PID=$!

# Run by background
StartTime=$(date '+%s')

i=0
for target in test_3_target_list_*
do
    ${ExecCommand} -i ${target} -o test_3_results_temp_$(printf "%05d" $i) &
    i=$((i+1))
done

# Wait
while [ $( ps -f |grep "${ExecCommand}"|grep -cv grep ) -gt 0 ]
do
    sleep 1
done
EndTime=$(date '+%s')

# Print result
echo "${rows},${NumOfParallels},$((EndTime-StartTime)),$(utcserial2date ${StartTime}),$(utcserial2date ${EndTime})" >> ${SummaryResultCSVFile}
echo "Result: ${rows},${NumOfParallels},$((EndTime-StartTime)),$(utcserial2date ${StartTime}),$(utcserial2date ${EndTime})" 

# Finall
kill -9 ${SAR_PID}
cat test_3_results_temp_* > test_3_results_${rows}_${NumOfParallels}.csv
rm test_3_results_temp_*
rm test_3_target_list_*
