#!/bin/bash

curl -s https://raw.githubusercontent.com/bombermine3/cryptohamster/main/logo.sh | bash && sleep 1

if [ $# -ne 1 ]; then 
	echo "Использование:"
	echo "ironfish.sh <command>"
	echo "	install   Установка ноды"
	echo "	uninstall Удаление"
	echo "	update    Обновление"
	echo "	backup    Бэкап"
	echo ""
fi

case "$1" in
install)
	cd $HOME	

	touch $HOME/.bash_profile
	source $HOME/.bash_profile

	if [ ! $IRONFISH_NODE_NAME ]; then
		read -p "Введите имя ноды: " IRONFISH_NODE_NAME
		echo 'export IRONFISH_NODE_NAME='${IRONFISH_NODE_NAME} >> $HOME/.bash_profile
	fi
	if [ ! $IRONFISH_THREADS ]; then
		read -e -p "Введите число потоков майнинга [-1]: " IRONFISH_THREADS
		echo 'export IRONFISH_THREADS='${IRONFISH_THREADS:--1} >> $HOME/.bash_profile
	fi
	source $HOME/.bash_profile
  
	apt update
	apt -y upgrade
	apt -y install curl
	curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
	apt update
	apt -y install build-essential nodejs
	source $HOME/.bash_profile

	npm install -g ironfish

	printf "[Unit]
Description=IronFish Node
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ironfish) start
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/ironfish-node.service


	printf "[Unit]
Description=IronFish Miner
After=network-online.target
[Service]
User=$USER
ExecStart=$(which ironfish) miners:start -v -t $IRONFISH_THREADS --no-richOutput -p pool.ironfish.network -a 7f6c19062e015a2f9ef350dc0dd410a8849eeea67c906e0e00692aa2d0ced505
Restart=always
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/ironfish-miner.service

	mkdir -p $HOME/.ironfish
	printf "{
		\"nodeName\": \"${IRONFISH_NODE_NAME}\",
		\"blockGraffiti\": \"${IRONFISH_NODE_NAME}\"
	}" > $HOME/.ironfish/config.json

	systemctl daemon-reload
	systemctl enable ironfish-node ironfish-miner
	systemctl start ironfish-node ironfish-miner

	sleep 5

	systemctl stop ironfish-node ironfish-miner
	sleep 2
	ironfish chain:download --confirm
	ironfish config:set enableTelemetry true
	systemctl restart ironfish-node ironfish-miner

	echo -e "\n" | ironfish faucet > /dev/null 2>&1

	echo "Установка завершена"
	echo "Проверка логов:"
	echo "   journalctl -u ironfish-node -f -o cat"
	echo "   journalctl -u ironfish-miner -f -o cat"
        
	;;
uninstall)
	systemctl disable ironfish-node ironfish-miner
	systemctl stop ironfish-node ironfish-miner 
	rm -rf $HOME/ironfish $HOME/.ironfish $(which ironfish)

	echo "Удаление завершено"
    ;;
update)
	sytemctl stop ironfish-node ironfish-miner
	cd $HOME

	mkdir -p ironfish_backup
	cp -r $HOME/.ironfish/databases/wallet $HOME/ironfish_backup/wallet_$(date +%s)
	
	npm install -g ironfish

	sytemctl restart ironfish-node ironfish-miner

	echo "Обновление завершено"
	;;
backup)
	
	;;
esac

