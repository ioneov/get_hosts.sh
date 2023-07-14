#!/bin/bash
fname="get_hosts.sh"
version="0.2"
repo="https://github.com/ioneov/get_hosts.sh"

# Menu Switches
arg_target="N"
arg_input="N"
arg_output="N"

# Variables
NAME_SUFFIX=$(/bin/date +%d-%m-%Y-%H:%M:%S)

function header () {
# header function  - used to print out the title of the script
echo "--------------------------------------------------------------------------------------"
echo -e "\e[1m             _       _               _             _     "
echo "   __ _  ___| |_    | |__   ___  ___| |_ ___   ___| |__  "
echo "  / _' |/ _ \ __|   | '_ \ / _ \/ __| __/ __| / __| '_ \ "
echo " | (_| |  __/ |_    | | | | (_) \__ \ |_\__ \_\__ \ | | |"
echo "  \__, |\___|\__|___|_| |_|\___/|___/\__|___(_)___/_| |_|"
echo "  |___/        |_____|                                   "
echo " "
echo -e "\e[39m\e[0m\e[96mVersion: $version\tRepository: $repo"
echo ""
echo "--------------------------------------------------------------------------------------"
}
function helpmenu () {
# show the options to use
header
echo
echo "[*] Usage: $fname [options]"
echo
echo -e "\e[93m[*] Options:"
echo
echo "	--target [hosts]	Subnet or host for realtime scanning with nmap"
echo "				Ex. 192.168.0.0/24 or 192.168.0.1"
echo "	--input [file]		Set a custom input file with hosts"
echo "	--output [file]		By default use STDOUT. Set a custom output directory"
echo "				Ex: --output /home/user/result.txt"
echo -e "\e[97m"
echo "[*] Output format:"
echo "--------------------------------------------------------------------------------------"
echo -e "IP\t|\tTCP ports\t|\tUDP ports\t|\tMAC\t|\tNetBIOS"
echo "--------------------------------------------------------------------------------------"
echo
echo -e "\e[95m[*] Example:"
echo
echo "$fname --target 192.168.0.1"
echo "$fname --input ips.txt --output result.txt"
echo "$fname --target 192.168.4.0/24 --output /home/user/result.txt"
echo -e "\e[97m"
}
function active () {
# Scanning hosts with nmap
echo "[*] Getting active addresses..."
if [ "$arg_target" != "N" ]
	then nmap -sn -T4 "$arg_target" 2> /dev/null | grep -Eo "Nmap scan report.*" | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}" >> temporary-ips-"$NAME_SUFFIX".txt # nmap ping
elif [ "$arg_input" != "N" ]
	then nmap -sn -T4 -iL "$arg_input" 2> /dev/null | grep -Eo "Nmap scan report.*" | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}" >> temporary-ips-"$NAME_SUFFIX".txt # nmap ping
	# then fping -f $arg_input 2> /dev/null| grep "is alive" | awk '{print $1}' >> temporary-ips-"$NAME_SUFFIX".txt # fping ping
else
	echo "[*] Unknown error..."
fi
while IFS= read -r line;do
	if [ "$arg_output" != "N" ]
		then  echo "[*] Getting TCP ports for $line...";
		        nmap -p1-65535 --open -n -T4 "$line"  > temporary-"$line"-tresult-"$NAME_SUFFIX".txt;
			grep -v "filtered" temporary-"$line"-tresult-"$NAME_SUFFIX".txt | grep -E "^[0-9]" | cut -d '/' -f 1 | tr '\n' ',' | sed -e "s/,$//g" > temporary-"$line"-tports-"$NAME_SUFFIX".txt;
			grep -v "filtered" temporary-"$line"-tresult-"$NAME_SUFFIX".txt | grep -E "^MAC Address" | awk '{print $3}' > temporary-"$line"-mac-"$NAME_SUFFIX".txt;
			rm temporary-"$line"-tresult-"$NAME_SUFFIX".txt 2> /dev/null;
			echo "[*] Getting UDP ports for $line...";
			nmap -sU -sV --version-intensity 0 -F -n -T4 --open  "$line"  >  temporary-"$line"-ureluslt-"$NAME_SUFFIX".txt;
			grep -v "filtered" temporary-"$line"-uresult-"$NAME_SUFFIX".txt | grep -E "^[0-9]" | cut -d '/' -f 1 | tr '\n' ',' | sed -e "s/,$//g" > temporary-"$line"-uports-"$NAME_SUFFIX".txt;
			rm temporary-"$line"-ureluslt-"$NAME_SUFFIX".txt 2> /dev/null;
        		echo "[*] Getting NetBIOS name for $line...";
			nbtscan -r "$line" -l | head -n 1 | awk '{print $2}' | sed -e "s/<unknown>//" > temporary-"$line"-nbios-"$NAME_SUFFIX".txt;
			echo -e "$line\t$(cat temporary-"$line"-tports-"$NAME_SUFFIX".txt 2> /dev/null)\t$(cat temporary-"$line"-uports-"$NAME_SUFFIX".txt 2> /dev/null)\t$(cat temporary-"$line"-mac-"$NAME_SUFFIX".txt 2> /dev/null)\t$(cat temporary-"$line"-nbios-"$NAME_SUFFIX".txt 2> /dev/null)" >> "$arg_output"
	elif [ "$arg_output" == "N" ]
		then nmap -p1-65535 --open -n -T4 "$line"  > temporary-"$line"-result-"$NAME_SUFFIX".txt;
 			grep -v "filtered" temporary-"$line"-result-"$NAME_SUFFIX".txt | grep -E "^[0-9]" | cut -d '/' -f 1 | tr '\n' ',' | sed -e "s/,$//g" > temporary-"$line"-tports-"$NAME_SUFFIX".txt;
			grep -v "filtered" temporary-"$line"-result-"$NAME_SUFFIX".txt | grep -E "^MAC Address" | awk '{print $3}' > temporary-"$line-mac-$NAME_SUFFIX".txt;
			rm temporary-"$line"-tresult-"$NAME_SUFFIX".txt 2> /dev/null;
			nmap -sU -sV --version-intensity 0 -F -n -T4 --open  "$line"  > temporary-"$line"-uresult-"$NAME_SUFFIX".txt;
			grep -v "filtered" temporary-"$line"-uresult-"$NAME_SUFFIX".txt | grep -E "^[0-9]" | cut -d '/' -f 1 | tr '\n' ',' | sed -e "s/,$//g" > temporary-"$line"-uports-"$NAME_SUFFIX".txt;
			rm temporary-"$line"-ureluslt-"$NAME_SUFFIX".txt 2> /dev/null;
			nbtscan -r "$line" -l | head -n 1 | awk '{print $2}'| sed -e "s/<unknown>//" > temporary-"$line"-nbios-"$NAME_SUFFIX".txt;
			echo -e "$line\t$(cat temporary-"$line"-tports-"$NAME_SUFFIX".txt 2> /dev/null)\t$(cat temporary-"$line"-uports-"$NAME_SUFFIX".txt 2> /dev/null)\t$(cat temporary-"$line"-mac-"$NAME_SUFFIX".txt 2> /dev/null)\t$(cat temporary-"$line"-nbios-"$NAME_SUFFIX".txt 2> /dev/null)"
	else
		echo "[*] Unknown error..."
	fi
	rm temporary-*
done < temporary-ips-"$NAME_SUFFIX".txt
echo "[*] Done..."
}

# MAIN
helpmenu
echo -e "\e[97m"
# Get args
while [[ "$#" -gt 0 ]];do
	case "$1" in
		--target) arg_target="$2"
		shift;;
		--input) arg_input="$2"
		shift;;
		--output) arg_output="$2"
		shift;;
		*) echo "[*] Unknown option: $1..."
		exit 1;;
	esac
shift
done
# Check options
if [ "$arg_target" != "N" ] && [ "$arg_input" != "N" ]
	then echo "[*] Incompatible options: --input and --target"
elif [ "$arg_target" != "N" ] || [ "$arg_input" != "N" ]
	then active
else
	echo "[*] Chose options --input or --target for start..."
fi
# exit
exit 0