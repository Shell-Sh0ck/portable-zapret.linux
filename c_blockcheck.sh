#!/bin/bash

usage() {
	echo "Created by Shell-Shock v1.0.0"
  	echo "https://github.com/Shell-Sh0ck"
    	echo ""
    	echo "Options:"
    	echo "   -u selects a list to check."
	echo "   -c specifies --connect-timeout for curl. (default: 3)"
   	echo "   -h          Show help"
    	exit 0
}

check_tlshandhsake() {
	local ping="false" \
	      curl="false"

	for url in $(cat $1)
	do
		if [[ $(curl -s --tlsv1.3 -o /dev/null --connect-timeout "$2" --max-time "5" -w "%{http_code}" "https://$url") != "000" ]]; then 
			curl="true"
		fi
		if ping -c 2 "$url" > /dev/null 2>&1; then 
			ping="true"
		fi
		echo -e "$url - \033[44mping:$ping - curl:$curl\033[0m"
	done
}

main() {
	local  con_timeout="3"

	for cmd in curl; do
    		if ! command -v $cmd &> /dev/null; then
        		echo "Error: $cmd is not installed."
        		exit 1
    		fi
	done

	while getopts ":u:c:h" opt; do
        	case $opt in
            	u) link_list="$OPTARG" ;;
            	c) con_timeout="$OPTARG" ;;
            	h) usage; exit 0 ;;
            	\?) echo "Invalid option: -$OPTARG"; usage ; exit 1 ;;
            	:) echo "Option -$OPTARG requires an argument"; usage ; exit 0 ;;
        	esac
    	done

	check_tlshandhsake "$link_list" "$con_timeout"
}

main "$@"
