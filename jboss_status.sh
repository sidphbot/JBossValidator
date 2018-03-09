red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m'

diskthres=85
heapthres=85

_checkDisk(){
disk=$1

DISK=`df -h |grep $disk|awk '{printf "%s\t\t", $5}'|cut -f 1 -d "%"`

if [ $DISK -le $diskthres ];then

echo -e "\n ${green}Disk : $disk\nUSAGE=${DISK}\n${nc}"

else

echo -e "\n ${red}Disk : $disk\nUSAGE=${DISK}\n${nc}"

fi

}


_checkMem(){

MEMORY=$(free -m | awk 'NR==2{printf "%.2f%%\t\t", $3*100/$2 }'|cut -f 1 -d "%")

if [ $MEMORY -le $memthres ];then

echo -e \n ${green}MEM=${MEMORY}${nc}

else

echo -e \n ${red}MEM=${MEMORY}${nc}


fi
}

_checkCPU(){

CPU=$(top -bn1 | grep load | awk '{printf "%.2f%%\t\t\n", $(NF-2)}'|cut -f 1 -d "%")

if [ $CPU -le $cputhres ];then

echo -e \n ${green}CPU=${CPU}${nc}

else

echo -e \n ${red}CPU=${CPU}${nc}

fi
}


_JbossStatus(){
user=$1

JBOSS_DIR=`ps -ef |grep jboss |grep $user |grep "\-server" |tr " " "\n" |grep "\-Djboss\.home\.dir" |cut -d "=" -f 2`
JBOSS_HOME=${JBOSS_DIR}/bin

echo -e "\nUser: $user\nJBoss_dir: $JBOSS_DIR\nJBoss_bin: $JBOSS_HOME"

#server_base=

#server_log

#server_tmp

portlist=(`ps -ef |grep jboss |grep $user|grep -v grep |grep "\-server"|tr " " "\n" |grep "\-Djboss\.socket\.binding\.port\-offset" |cut -d "=" -f 2|sort -u`)
for port in ${portlist[@]}
do 
portoffed=`expr 9990 + $port`
httpportoffed=`expr 8080 + $port`

echo -e "\n JBOSS_PROCESS_STATUS"
echo -e "\n --------------------"

echo -e "\n Port : $httpportoffed"

pid=`ps -ef |grep standalone.sh |grep -v grep |grep $user|awk '{print $2}' `

if [ "$pid" == "" ]; then
echo  -e "\n ${red}"there is no jboss process for $user user"${nc}"
else
echo -e "\n ${green}"pid: $pid"${nc}"
fi

pid2=`ps -ef |grep $pid |grep '\-D\[Standalone\]' |grep -v grep |awk '{print $2}'`
fdcount=`ls -lrt /proc/$pid2/fd|wc -l`
fdlimit=`more /proc/$pid2/limits |grep 'Max open files' |awk '{print $4}'`

echo -e "\nThe file descriptor count is : $fdcount"
echo -e "\nThe file descriptor limit is : $fdlimit"

jbossstate=`sudo su - $user -c "${JBOSS_HOME}/jboss-cli.sh -c --controller=localhost:$portoffed --commands='ls' |grep server-state|cut -d '=' -f 2"`

if [ "$jbossstate" == "running" ];then
echo -e "\n ${green}"The JBoss instance is not hung and well reachable"${nc}"
else
echo -e "\n ${red}"CLI creds are not configured or the instance is hung"${nc}"
continue
fi

if [ "`netstat -anlp |grep $httpportoffed |grep -v grep`" == "" ]
then

echo -e "\n ${red}"the netstat signature is not present"${nc}"

else

echo -e "\n The netstat signature is :"
netstat -anlp |grep $httpportoffed |grep -v grep
fi

if [ "`curl localhost:${httpportoffed}`" == "" ]
then

echo -e "\n ${red}"the curl signature is not present"${nc}"

else

echo -e "\n The webpage at $httpportoffed is available and can be browsed or curl\-ed"

fi 


echo -e "\n checking related disks.."

rel_disks=(`sudo su - $user -c "${JBOSS_HOME}/jboss-cli.sh -c --controller=localhost:$portoffed --commands='ls core-service=server-environment'| grep '=/.*/'|cut -d '/' -f 2 |sort -u|tr '\n' ' '|sed 's/ $//g'"`)

for i in "${rel_disks[@]}"
do
_checkDisk $i
done

heap=`sudo su - $user -c "${JBOSS_HOME}/jboss-cli.sh -c --controller=localhost:$portoffed --commands='/core-service=platform-mbean/type=memory:read-attribute(name=heap-memory-usage)'|grep used"|awk '{print $3}'|cut -d 'L' -f 1`

heapmax=`sudo su - $user -c "${JBOSS_HOME}/jboss-cli.sh -c --controller=localhost:$portoffed --commands='/core-service=platform-mbean/type=memory:read-attribute(name=heap-memory-usage)'|grep max"|awk '{print $3}'|cut -d 'L' -f 1`

#heapperc=$(echo -e "scale=2\n($heap*100)/$heapmax"|bc)
#heapgb=$(echo -e "scale=2\n(($heap/1025)/1024)/1024"|bc)
#heapmaxgb=$(echo -e "scale=2\n(($heapmax/1025)/1024)/1024"|bc)

heapperc=$(awk -v heap="$heap" -v heapmax="$heapmax" 'BEGIN {print (heap*100)/heapmax}')
heapgb=$(awk -v heap="$heap" 'BEGIN {print ((heap/1025)/1024)/1024}')
heapmaxgb=$(awk -v heapmax="$heapmax" 'BEGIN {print ((heapmax/1025)/1024)/1024}')

if [ $( printf "%.0f" $heapperc) -le $heapthres ];then

echo -e "\n${green}Heap usage : $heapgb "GB / "$heapmaxgb "GB \( "${heapperc}"% \)"${nc}"

else

echo -e "\n${red}Heap usage : $heapgb" GB / "$heapmaxgb" GB \( "${heapperc}"% \)"${nc}"

fi

thread=`sudo su - $user -c "${JBOSS_HOME}/jboss-cli.sh -c --controller=localhost:$portoffed --commands='/core-service=platform-mbean/type=threading:read-attribute(name=thread-count)'|grep result|awk '{print $3}'"`
echo -e "\nThread Count : $thread"

echo -e "\n-------------done------------"

done

}

jbusers=(`ps -ef |grep jboss |grep -v rhq|grep -v grep |cut -f 1 -d " " |sort -u|tr "\n" " " |sed -e 's/ $//g'`)


for i in "${jbusers[@]}"
do
_JbossStatus $i

#testdb

done

