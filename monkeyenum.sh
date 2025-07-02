#!/bin/bash
#
# I am lazy. This script will help you enumerate targets. It outputs various commands and I save it into text files based on how verbose the output is likely to be.
# It is a work in progress, and lacks a lot of input validatio nat the moment. If you do find some use out of it enjoy :)
#
#
#   .--.  .-"     "-.  .--.
#  / .. \/  .-. .-.  \/ .. \
# | |  '|  /   Y   \  |'  | |
# | \   \  \ 0 | 0 /  /   / |
#  \ '- ,\.-"`` ``"-./, -' /
#   `'-' /_   ^ ^   _\ '-'`
#       |  \._   _./  |
#       \   \ `~` /   /
#jgs     '._ '-=-' _.'
#           '~---~'
# Monkey ascii art from https://www.asciiart.eu/animals/monkeys
#
#
#                     *** Do NOT use this for illegal or malicious use ***                     #
#                By running this, YOU are using this program at YOUR OWN RISK.                 #
#            This software is provided "as is", WITHOUT ANY guarantees OR warranty.	       #

# Usage:
# ./monkeyenum.sh
#
# Version: 0.1
#
# Author: Alexanderpubnotes (Github)
#
MSG_HELP="
 Description:

 This script connects to a given server and depending on user input will run commands based on option picked

 Usage:

 ./monkeyenum.sh -s 192.168.1.1 -u 'user' -p 'P@ssw0rd' -d MEGABANK.LOCAL ( -l )

 Options:

 General
 -s, --server SERVER_IP		Specify server's IP address [REQUIRED]
 -u, --user USERNAME		Specify username
 -p, --password PASSWORD	Specify user's password
 -d, --domain			Specify server's domain
 -c, --comname			Common Name

 LDAP
 -l, --ldap			LDAP enumeration

 RPC
 -r, --rpc			RPC enumeration

"
if [ "$*" == "" ]
then
	echo "$MSG_HELP"
	exit 0
fi

# Default options
SERVER_IP=0
USER=''
PASS=''
DOMAIN="WORKGROUP"
ONLY_USERS=0
COMMON_NAME="DOOFUS TEST"
LDAP=0
RPC=0

# Options handling
while test -n "$1"
do
	case "$1" in
		-s | --server)
			SERVER_IP=$2
			shift
			;;

		-u | --user)
			USER=$2
			shift
		;;
		-p | --password)
			PASS=$2
			PASS_FROM_CMD=1
			shift
		;;
		-d | --domain)
			DOMAIN=$2
			shift
		;;
		-o | --only-users)
			ONLY_USERS=1
			shift
		;;
		-l | --ldap)
			LDAP=1
			shift
		;;
		-c | --comname)
			COMNAME=$2
			shift
		;;
		-r | --rpc)
			RPC=1
			shift
		;;
*)
			echo "Invalid option: $1"
			exit 1
		;;
	esac
	shift
done

# Validation of required options
if [ ${SERVER_IP} == 0 ]
then
	echo "Option --server required!"
	exit 1
fi


if [ ${LDAP} -eq 1 ]
then

	IFS='.' read -r DOMAINL DOMAINR <<< "${DOMAIN}"
	IFS=' ' read -r COMNAMEL COMNAMER <<< "${COMNAME}"

	RESULT="ldapsearch -x -H ldap://${SERVER_IP} -b \"\" -s base \"(objectclass=*)\" > base.txt"
	RESULT2="ldapsearch -x -H ldap://${SERVER_IP} -D '${USER}@${DOMAIN}' -w '${PASS}' -b \"DC=${DOMAINL},DC=${DOMAINR}\" > verbose.txt"
	#RESULT3="ldapsearch -x -D '${USER}@${DOMAIN}' -w '${PASS}' -H ldap://${SERVER_IP} -b \"CN=${COMNAMEL},CN=${COMNAMER},DC=${DOMAINL},DC=${DOMAINR}\" > verbose2.txt"

	bash -c "${RESULT}"
        bash -c "${RESULT2}"
        #bash -c "${RESULT3}"
fi


if [ ${RPC} -eq 1 ]
then

DOMAIN_SID=$(rpcclient -U "${USER}"%"${PASS}" ${SERVER_IP} -W ${DOMAIN} -c "lookupnames administrator" | grep -v "password:" | cut -d" " -f 2 | cut -d"-" -f 1-7)


SIDS=""
for num in $(seq 500 2000)
do
	SIDS="${SIDS} ${DOMAIN_SID}-${num}"
done

RESULT="rpcclient -U '${USER}'%'${PASS}' ${SERVER_IP} -W '${DOMAIN}' -c 'lookupsids ${SIDS}' | grep -v '*unknown*' | grep -v '00000'"

bash -c "${RESULT}"
fi
