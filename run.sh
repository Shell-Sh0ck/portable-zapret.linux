#!/bin/bash

usage() {
echo "Created by Shell-Shock v1.0.0"
    	echo "https://github.com/Shell-Sh0ck"
    	echo ""
    	echo "Options:"
    	echo "   -i selects the interface."
    	echo "   -a selects the configuration."
    	echo "   -q selects qnum."
	echo "   -l displays all available configurations."
    	echo "   -h Show help"
    	exit 0
}

iptbls_rules_run() {
iptables -t mangle -I POSTROUTING -o $1 -p tcp -m multiport \
	--dports 80,443,1024:65535 -m connbytes --connbytes-dir=original \
		--connbytes-mode=packets --connbytes 1:6 -m mark ! --mark 0x40000000/0x40000000 \
			-j NFQUEUE --queue-num $2 --queue-bypass

iptables -t mangle -I POSTROUTING -o $1 -p udp -m multiport \
	--dports 443,1024:65535 -m mark ! --mark 0x40000000/0x40000000 \
		-j NFQUEUE --queue-num $2 --queue-bypass
}

setup_nftables() {
	local interface="$1" \
		table_name="inet zapret" \
		chain_name="output" \
		rule_comment="zapret_s"
		queue_num="$2" \
		oif_clause=""

	if sudo nft list tables | grep -q "$table_name"; then
		sudo nft flush chain $table_name $chain_name
		sudo nft delete chain $table_name $chain_name
		sudo nft delete table $table_name
	fi

	sudo nft add table $table_name
	sudo nft add chain $table_name $chain_name { type filter hook output priority 0\; }

	if [ -n "$interface" ] && [ "$interface" != "any" ]; then
		oif_clause="oifname \"$interface\""
	fi

	if [ -n "$3" && -n "$3" ]; then
		sudo nft add rule $table_name $chain_name $oif_clause meta mark != 0x40000000 tcp dport {$3} counter queue num $queue_num bypass comment \"$rule_comment\"
		sudo nft add rule $table_name $chain_name $oif_clause meta mark != 0x40000000 udp dport {$3} counter queue num $queue_num bypass comment \"$rule_comment\"
	fi
}

main() {
        local  zapret_path="./binaries/linux-x86_64" \
               args_path="./args" \
	       GAME_FILTER_TCP="1024-65535" \
	       GAME_FILTER_UDP="1024-65535" \
	       hostlists="./ipset" \
	       fakebin="./files/fake"

        for cmd in gettext; do
                if ! command -v $cmd &> /dev/null; then
                        echo "Error: $cmd is not installed."
                        exit 1
                fi
        done

        while getopts "q:i:a:lh" opt; do
                case $opt in
		q) qnum="$OPTARG" ;;
		i) interface="$OPTARG" ;;
                a) arg_select="$OPTARG" ;;
		l) args=true ;;
                h) usage; exit 0 ;;
                \?) echo "Invalid option: -$OPTARG"; usage ; exit 1 ;;
                :) echo "Option -$OPTARG requires an argument"; usage ; exit 0 ;;
                esac
        done

        if [ -f $zapret_path/nfqws ]; then
		if [[ "$args" = true ]]; then
                	ls "$args_path" | sort
        	fi

        	if [[ $arg_select != "" ]]; then
			source "$args_path/$arg_select"
			setup_nftables "$interface" "$qnum" "$GAME_FILTER_TCP"
                	$zapret_path/nfqws --qnum "$qnum" ${args[@]}
        	fi
	else
		echo "$zapret_path/nfqws not found"
                exit 1
	fi
}

main "$@"
