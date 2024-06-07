#! /bin/sh


# Configuration   
# Fill in all the placeholders marked with TODO

institution="TODO"
kramUrl="localhost:8088"
#removeLog=1
sshUser="TODO"
DNNTLogs=TODO


cd $DNNTLogs


if [ $# -eq 0 ]; then
    dateFrom=`date --date="1 days ago" +"%Y"."%m"."%d"`;
    dateTo=`date +"%Y"."%m"."%d"`;
elif [ $# -eq 1 ]; then
    dateFrom="$1"
    dateFromRep=$(echo "$1" | sed 's/\./-/g')
    dateTo=$(date -d "$dateFromRep + 1 day" "+%Y.%m.%d")
else
    dateFrom="$1"
    dateTo="$2"
fi

echo "Date from $dateFrom"
echo "Date to $dateTo"

file="statistics-$institution-$dateFrom.log"

echo "Generating file $file"
echo "Output folder $DNNTLogs"
echo "SSH user $sshUser"
   

curl --verbose -X POST $kramUrl/search/api/admin/v7.0/processes \
     -H "Content-Type: application/json" \
     -H "X-Forwarded-For: TODO" \
     -d '{"defid":"nkplogs","params":{"dateFrom":"'"$dateFrom"'","dateTo":"'"$dateTo"'","emailNotification":false}}'


sshfolder=$(echo "$dateFrom" | sed 's/\./-/g')
echo "SSH Folder $sshfolder"
sshfolder=$(echo "$sshfolder" | cut -c1-7)
echo "SSH Folder cut $sshfolder"

sleep 300 && sftp -oPort=47272 $sshUser.sftp@195.113.133.21  << !
   mkdir statistics
   cd statistics
   mkdir $sshfolder
   cd $sshfolder
   put $DNNTLogs/$file
   bye
!

