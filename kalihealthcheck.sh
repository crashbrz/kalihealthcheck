#!/usr/bin/env bash

export logfile=kalicheck.log
export update=('apt update && apt upgrade' 'apt-get update && apt-get dist-upgrade')
export repos=('/etc/apt/sources.list')
export docs=('http://docs.kali.org/general-use/kali-linux-sources-list-repositories')
export kernel=("$(uname -v | awk '{print$4}')" "curl -sL http://pkg.kali.org/linux | awk '/version:/ {getline;print$1}'")
export userhashlist=userhashlist.txt
export dirlist=dislist.txt
export filelist=filelist.txt
export hc=/usr/bin/sha1sum
export originalhashlist=originalhashlist.txt
clear
rm -f  originalhashlist 2> /dev/null
printf '\e[4m\e[1m%s\n\e[0m' "Kali Health Check"

printf '%s\n' "[-] Checking sources.list file..." | tee $logfile

if [[ -s "$repos" ]] && [[ "$(grep -v '#' /etc/apt/sources.list | sed '/^$/d' | wc -l)" != 1 ]] ;
then
	printf '\e[91m\e[1m%s\n\e[0m' "Non-standard repository configuration detected. - [FAIL]" | tee -a $logfile
	printf '%s\n' "Please check this documentation: "$repos"."
	printf '%s\n' "Any additional repositories added to Kali's sources.list file will most likely BREAK YOUR INSTALL."
	printf '%s\n' "++++++++++SOURCES++++++++++" >> $logfile
	cat               /etc/apt/sources.list     >> $logfile
	printf '%s\n' "+++++++++++++++++++++++++++" >> $logfile
else
	printf '%s\n' "[-] Checking repository URL..."

	if grep -q "deb http://http.kali.org/kali kali-rolling main contrib non-free" <<< "$(grep -v '#' /etc/apt/sources.list | sed '/^$/d')" ||
	   grep -q "deb http://http.kali.org/kali kali-rolling main non-free contrib" <<< "$(grep -v '#' /etc/apt/sources.list | sed '/^$/d')" ;
	then
		printf '\e[92m\e[1m%s\n\e[0m' "Standard repository configuration detected. - [PASS]" | tee -a $logfile

	else
		printf '\e[91m\e[1m%s\n\e[0m' "Non-standard repository configuration detected. - [FAIL]" | tee -a $logfile
		printf '%s\n' "Please check this documentation: http://docs.kali.org/general-use/kali-linux-sources-list-repositories."
		printf '%s\n' "Any additional repositories added to Kali's sources.list file will most likely BREAK YOUR INSTALL."
		printf '%s\n' "++++++++++SOURCES++++++++++" >> $logfile
		cat               /etc/apt/sources.list     >> $logfile
		printf '%s\n' "+++++++++++++++++++++++++++" >> $logfile

		printf '%s\n' "Do you want to restore your repository configuration's default settings? [y/n]."

		read -n 1 -r -s restore
		case "$restore" in
			y)
				cat <<-EOF > /etc/apt/sources.list
				deb http://http.kali.org/kali kali-rolling main contrib non-free
				# For source package access, uncomment the following line
				# deb-src http://http.kali.org/kali kali-rolling main contrib non-free
				EOF

				printf '%s\n' "Restoring file: '/etc/apt/sources.list', to default." | tee -a $logfile
				printf '%s\n' "Done."
				;;
			n)
				printf '%s\n' "No changes were made."
				;;
			*)
				printf '%s\n' "[y/n]."
				;;
		esac
	fi
fi

printf '%s\n' "[-] Checking kernel..." | tee -a $logfile

if grep -q "$(curl -s http://pkg.kali.org/pkg/linux | grep -A 1 version: | sed '1d' | sed 's/ //g')" <<< "$(uname -v)" ;
then
	printf '\e[92m%s\n\e[0m' "Latest kernel detected. - [PASS]" | tee -a $logfile
else
	printf '\e[91m\e[1m%s\n\e[0m' "Latest kernel not detected. - [FAIL]" | tee -a $logfile
printf 'Consider running \e[1m%s\e[0m to get up to date.\n' "$update"
	printf '%s\n' "++++++++++KERNEL+++++++++++" >> $logfile
	printf '%s\n' "Current machine kernel" >> $logfile
	uname -a >> $logfile
	printf '%s\n' "Last kernel in repo:" >> $logfile
	echo $kernel >>$logfile
	
	
	printf '%s\n' "+++++++++++++++++++++++++++" >> $logfile
fi

printf '%s\n' "[-] Checking packages..." | tee -a $logfile
if grep -q "$(curl -s http.kali.org/kali/dists/ | grep  kali-rolling | sed '1d' | sed -e 's/<[^>]*>//g' | cut -b 14-23)" <<< "$(tail -1 /var/log/apt/history.log | cut -b 11-21)" ;
then
	printf '\e[92m\e[1m%s\n\e[0m' "Your system is up to date. - [PASS]" | tee -a $logfile
	tail -1 /var/log/apt/history.log | cut -b 11-21  >> $logfile
else
	printf '\e[91m\e[1m%s\n\e[0m' "Your system is not up to date. - [FAIL]" | tee -a $logfile
	printf '%s\n' "Your last update was on \"$(tail -1 /var/log/apt/history.log | cut -b 11-20)\"."
	printf '%s\n' "The latest content became available on \"$(curl -s http.kali.org/kali/dists/ | grep 'kali-rolling' | sed '1d' | sed -e 's/<[^>]*>//g' | cut -b 14-23)\"."
	printf 'Consider running \e[1m%s\e[0m to get up to date.\n' "$update"
	printf '%s\n' "+++++++LATEST+UPDATE+++++++"      >> $logfile
        tail -1 /var/log/apt/history.log | cut -b 11-21  >> $logfile
        printf '%s\n' "+++++++++++++++++++++++++++"      >> $logfile
fi

printf '%s\n' "[-] Fetching Mirror list..." | tee -a $logfile
curl -sI http://http.kali.org/README  >> $logfile
curl -sI http://http.kali.org/README  | grep -i  "MirrorBrain" 
printf '%s\n' "+++++++++++++++++++++++++++" | tee -a $logfile

printf '%s\n' "[-] Checking disk usage..." | tee -a $logfile
df -h| grep -vE '^Filesystem|cdrom|tmpfs' | awk '{ print $5 " " $1 }' | while read dfoutput;
do
  part=$(echo $dfoutput | awk '{ print $2 }' )
  usage=$(echo $dfoutput | awk '{ print $1}' | cut -d'%' -f1  )
    if [ $usage -ge 90 ]; then
        printf '\e[91m\e[1m%s\n\e[0m' "Please consider to clean your particion $part. Disk usage above $usage% - [FAIL]" | tee -a $logfile
 fi 
 if [ $usage -le 90 ]; then
        printf '\e[92m%s\n\e[0m' "Disk usage is $usage% in $part - [PASS]" | tee -a $logfile
 fi   
done
#Thanks muts for the suggestion 
printf '%s\n' "[-] Collecting system logs..." | tee -a $logfile
printf '\e[91m\e[1m%s\n\e[0m' "Please, consider to clear the logs(/var/log/messages /var/log/kern.log /var/log/syslog /var/log/user.log), reproduce the bug and run this script again to better locate the issue." | tee -a $logfile
sleep 1
printf '%s\n' "++++++++++LOG: MESSAGES+++++++++++" >> $logfile
cat /var/log/messages >> $logfile
printf '%s\n' "[-] MESSAGES - [DONE"] | tee -a $logfile
printf '%s\n' "+++++++++++++++++++++++++++" >> $logfile
printf '%s\n' "++++++++++LOG: KERN.LOG+++++++++++" >> $logfile
cat /var/log/kern.log >> $logfile
printf '%s\n' "[-] KERN.LOG - [DONE"] | tee -a $logfile
printf '%s\n' "+++++++++++++++++++++++++++" >> $logfile
printf '%s\n' "++++++++++LOG: SYSLOG+++++++++++" >> $logfile
cat /var/log/syslog >> $logfile
printf '%s\n' "[-] SYSLOG - [DONE"] | tee -a $logfile
printf '%s\n' "+++++++++++++++++++++++++++" >> $logfile
printf '%s\n' "++++++++++LOG: USER.LOG+++++++++++" >> $logfile
cat /var/log/user.log >> $logfile
printf '%s\n' "[-] USERLOG - [DONE"] | tee -a $logfile
printf '%s\n' "+++++++++++++++++++++++++++" >> $logfile
printf '%s\n' "[-] Collecting system info..." | tee -a $logfile
printf '%s\n' "++++++++++DMESG+++++++++++" >> $logfile
dmesg >> $logfile
printf '%s\n' "[-] DMESG - [DONE"] | tee -a $logfile
printf '%s\n' "+++++++++++++++++++++++++++" >> $logfile

printf '\e[91m\e[1m%s\n\e[0m' "Would you like to perform a deep checking ***EXPERIMENTAL and TAKES A LONG TIME - 64bit only [y/N]." 
read -n 1 -r -s choice
if [[ "$choice" != *[yY]* ]] ;
then
	printf '%s\n' "Deep checking skipped" | tee -a $logfile
else
/usr/bin/apt-file update
echo "/usr/share/metasploit-framework/lib/snmp" > ${dirlist}
echo > "${filelist}"
echo -n > "${userhashlist}"
while IFS= read -r line
do
	find "${line}" -iname "*" -type f | egrep -iv "(\.png$|\.jpg$|\.gif$|\.jpeg$|\.ico$|\.svg$|\.log$|\.gz$|\.tar$|\.page$|\.css$|\.zip$|\.mo$|exploitdb|password|shadow)" > "${filelist}" #retrives file list
	while IFS= read -r line2
	do
		echo "$("${hc}" "${line2}")" | tee -a "${userhashlist}" 
	done < "${filelist}" 
    
done < "${dirlist}"
#### Download original hash list ####
#####################################
echo " Downloading Original Hask List"
wget https://github.com/crashbrz/kalihealthcheck/raw/master/originalfilehash.txt.tar.gz
tar -xzvf  originalfilehash.txt.tar.gz
mv originalfilehash.txt originalhashlist.txt
####################################
while IFS= read -r linecheck #While read the old list of files.
do
	originalfilepath=$(echo "${linecheck}" | rev | cut -d / -f 2-99999 | rev | cut -d " " -f 3-99999)
	originalfilename=$(echo "${linecheck}" | rev | cut -d / -f 1 | rev)
	originalfilehash=$(echo "${linecheck}" | awk '{print $1}')
	mergefilepath="${originalfilepath}/${originalfilename}"
	userfilepath=$(cat ${userhashlist} | grep "${mergefilepath}$" | rev | cut -d / -f 2-99999 | rev)
	userfilename=$(cat ${userhashlist} | grep "${mergefilepath}$" | rev | cut -d / -f 1 | rev)
	userfilehash=$(cat ${userhashlist} | grep "${mergefilepath}$" | awk '{print $1}')
      	
	if test "${userfilehash}" != "${originalfilehash}" ; then
		echo "===============================================================" | tee -a $logfile
		echo "The file: "${mergefilepath}"" | tee -a $logfile
		echo "doesn't match with the original Kali Linux last version file" | tee -a $logfile
		echo "===============================================================" | tee -a $logfile
		echo "In order to solve this issue, please remove and reinstall the package:" | tee -a $logfile
		pkgname=$(/usr/bin/apt-file find ${mergefilepath} | cut -d : -f1)  
		echo "${pkgname}"  | tee -a $logfile
		/usr/bin/apt-get download "${pkgname}"
		dpkg -x *.deb .
		echo "Following  the currupted information:" | tee -a $logfile
		diff -C0 "${mergefilepath}" "./${mergefilepath}"  | tee -a $logfile
		else
	
		echo "OK - ${mergefilepath}"
	fi

done < "${originalhashlist}"

fi

printf '%s\n' "A log file has been generated." "Would you like to share it online? [Y/n]."
read -n 1 -r -s choice
if [[ "$choice" != *[nN]* ]] ;
then
	printf 'Generating URL: \e[1m'
	nc termbin.com 9999 < $logfile
fi

### END ###
