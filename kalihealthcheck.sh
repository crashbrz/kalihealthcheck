#!/usr/bin/env bash

export logfile='/tmp/kalicheck.txt'
export update=('apt update && apt upgrade' 'apt-get update && apt-get dist-upgrade')
export repos=('/etc/apt/sources.list')
export docs=('http://docs.kali.org/general-use/kali-linux-sources-list-repositories')
export kernel=("$(uname -v | awk '{print$4}')" "curl -sL http://pkg.kali.org/linux | awk '/version:/ {getline;print$1}'")
clear
sleep 0.125
printf '\e[4m\e[1m%s\n\e[0m' "Kali Health Check"
sleep 1
printf '%s\n' "[-] Checking sources.list file..." | tee $logfile

if [[ -s "$repos" ]] && [[ "$(grep -v '#' /etc/apt/sources.list | sed '/^$/d' | wc -l)" != 1 ]] ;
then
	printf '\e[91m\e[1m%s\n\e[0m' "Non-standard repository configuration detected. - [FAIL]" | tee -a $logfile
	sleep 0.125
	printf '%s\n' "Please check this documentation: "$repos"."
	sleep 0.125
	printf '%s\n' "Any additional repositories added to Kali's sources.list file will most likely BREAK YOUR INSTALL."
	sleep 0.125
	printf '%s\n' "++++++++++SOURCES++++++++++" >> $logfile
	cat               /etc/apt/sources.list     >> $logfile
	printf '%s\n' "+++++++++++++++++++++++++++" >> $logfile
else
	printf '%s\n' "[-] Checking repository URL..."
	sleep 0.125
	if grep -q "deb http://http.kali.org/kali kali-rolling main contrib non-free" <<< "$(grep -v '#' /etc/apt/sources.list | sed '/^$/d')" ||
	   grep -q "deb http://http.kali.org/kali kali-rolling main non-free contrib" <<< "$(grep -v '#' /etc/apt/sources.list | sed '/^$/d')" ;
	then
		printf '\e[92m\e[1m%s\n\e[0m' "Standard repository configuration detected. - [PASS]" | tee -a $logfile
		sleep 0.125
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
	5
printf 'Consider running \e[1m%s\e[0m to get up to date.\n' "$update"
	printf '%s\n' "++++++++++KERNEL+++++++++++" >> $logfile
	uname -a                                    >> $logfile
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

printf '%s\n' "A log file has been generated." "Would you like to share it online? [y/n]."
read -n 1 -r -s choice
if [[ "$choice" != *[nN]* ]] ;
then
	printf 'Generating URL: \e[1m'
	nc termbin.com 9999 < $logfile
fi

### END ###
