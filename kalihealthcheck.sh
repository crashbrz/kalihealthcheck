clear
export logfile=/tmp/kalicheck.txt
echo "Kali Health Check" | tee $logfile 
echo 
echo "Checking sources.list file..." | tee -a $logfile
if [ $(grep -v "#" /etc/apt/sources.list | sed '/^$/d' |wc -l) -ne 1 ]; then
	echo "It was found a wrong number of repositories configured in your kali. [FAIL]" | tee -a $logfile
	echo "Please check  this documentation: http://docs.kali.org/general-use/kali-linux-sources-list-repositories." 
	echo "Any additional repositories added to the Kali sources.list file will most likely BREAK YOUR KALI LINUX INSTALL."
	echo "++++++++++SOURCES++++++++++ >> $logfile 
	cat /etc/apt/sources.list  >>  $logfile
	echo "+++++++++++++++++++++++++++ >> $logfile
else
echo "Checking the repositorie URL"
if grep -q "deb http://http.kali.org/kali kali-rolling main contrib non-free" <<< $(grep -v "#" /etc/apt/sources.list | sed '/^$/d') || grep -q "deb http://http.kali.org/kali kali-rolling main non-free contrib" <<< $(grep -v "#" /etc/apt/sources.list | sed '/^$/d') ; then
echo "The repositories seems to be ok. [OK]" | tee -a $logfile 
else
	echo "Please check this documentation: http://docs.kali.org/general-use/kali-linux-sources-list-repositories. [FAIL]" | tee -a $logfile
        echo "Any additional repositories added to the Kali sources.list file will most likely BREAK YOUR KALI LINUX INSTALL."
fi
fi
echo "Checking Kernel..." | tee -a $logfile
if grep -q $(curl -s http://pkg.kali.org/pkg/linux | grep -A 1 version: | sed '1d' | sed 's/ //g') <<< $(uname -v); then
echo "Last kernel was found - [OK]" | tee -a $logfile
else
	echo "Your kernel is not up to date, please update it - [FAIL]" | tee -a $logfile
	echo "Maybe running apt update;apt upgrade could solve your problem."
	echo "++++++++++KERNEL++++++++++" >> $logfile
	uname -a  >>  $logfile
	echo "+++++++++++++++++++++++++++" >> $logfile
fi
echo "Checking the last update..." | tee -a $logfile 

if  grep -q $(curl -s http.kali.org/kali/dists/ | grep  kali-rolling | sed '1d' | sed -e 's/<[^>]*>//g' | cut -b 14-23) <<< $(tail -1 /var/log/apt/history.log | cut -b 11-21); then
echo "Your Kali seems to be updated -[OK]" | tee -a $logfile
tail -1 /var/log/apt/history.log | cut -b 11-21  >>  $logfile
else
	echo -n "Your Kali has a different update date. Your last update was "
	echo -n $(tail -1 /var/log/apt/history.log | cut -b 11-21)
	echo -n " and the last update in the repositorie was "
	echo -n $(curl -s http.kali.org/kali/dists/ | grep  kali-rolling | sed '1d' | sed -e 's/<[^>]*>//g' | cut -b 14-23)
	echo .
	echo "Please consider to double check it. [MANUAL CHECK]"
	echo "++++++++++LAST UPDATE++++++++++" >> $logfile
        tail -1 /var/log/apt/history.log | cut -b 11-21  >>  $logfile
        echo "+++++++++++++++++++++++++++" >> $logfile
fi

echo -n "Do you wanna post the log file?[Y/n]"
read choice
if [[ "$choice" != *[nN]* ]]; then 
echo "Following your log data url:"
cat $logfile | nc termbin.com 9999
fi
