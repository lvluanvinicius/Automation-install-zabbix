# a. Install Zabbix repository

# wget https://repo.zabbix.com/zabbix/4.4/debian/pool/main/z/zabbix-release/zabbix-release_4.4-1+buster_all.deb
# dpkg -i zabbix-release_4.4-1+buster_all.deb
# apt update

# b. Install Zabbix server, frontend, agent
# apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent

# c. Create initial database
# mysql -uroot -p

# mysql> create database zabbix character set utf8 collate utf8_bin;
# mysql> grant all privileges on zabbix.* to zabbix@localhost identified by 'password';
# mysql> quit;

# zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix

# d. Configure the database for Zabbix server
# Edit file /etc/zabbix/zabbix_server.conf
# DBPassword=password

# e. Configure PHP for Zabbix frontend
# Edit file /etc/zabbix/apache.conf, uncomment and set the right timezone for you.
# php_value date.timezone Europe/Riga

# f. Start Zabbix server and agent processes
# Start Zabbix server and agent processes and make it start at system boot.

# systemctl restart zabbix-server zabbix-agent apache2
# systemctl enable zabbix-server zabbix-agent apache2

# g. Configure Zabbix frontend

# Pegando a versão
# sudo curl https://repo.zabbix.com/zabbix/ -s | grep '<a href="' | cut -d '>' -f1 | cut -d '"' -f 2 | grep '/' | cut -d/ -f1> versions

# Pegando arquivos .deb
# curl https://repo.zabbix.com/zabbix/4.4/debian/pool/main/z/zabbix-release/ | grep '<a href=' |cut -d'>' -f2 |grep zabbix-release_ |cut -d'<' -f1 |grep '.deb'

#!/bin/bash
clear

red="\033[01;31m"
green="\033[01;32m"
yellow="\033[01;33m"
blue="\033[01;34m"
pattern="\033[00m"

dependencies() {
    echo
    echo -ne $green"checking the dependencies...\n$pattern"; sleep 1
    
	PROGRAMA=( "curl" "wget" "sed" "grep")
	for prog in "${PROGRAMA[@]}";do
        echo -ne "\033[00;32m----------------| $prog for dependencies "
		if ! hash "$prog" 2>/dev/null;then
			echo -e "\033[00;31m<<<Not installed!>>>\033[00;37m"
		else
			echo -e "\033[00;32m<<<Installed!>>>\033[00;37m"
		fi
		sleep 1
		
    done
        
    for prog_inst in "${PROGRAMA[@]}";do
        if ! hash "$prog_inst" 2>/dev/null;then
            echo -e "\n\033[00;32mTrying to install dependencies...\033[00m"
            gnome-terminal --geometry=60x20 --hide-menubar --window -x bash -c "apt-get update && sleep 3 && apt-get install $prog_inst && exit "
            sleep 0.5
        else
            sleep 0.5
            continue
        fi
    done
}

get_verions ()
{
    Versions=$(sudo curl https://repo.zabbix.com/zabbix/ -s | grep '<a href="' | cut -d '>' -f1 | cut -d '"' -f 2 | grep '/' | cut -d/ -f1 )
    until grep -E ^[0-9]+$ <<< $OPT_VERSION; do                
        cont=0
        for it in `echo $Versions`
        do 
            V[$cont]=$it
            cont=$(( $cont + 1))
        done 
        echo -e $green"Please choose an option: \n$pattern"
        for ((idx=0; idx < ${#V[@]}; idx++))
        do
            echo -e "> $yellow ($idx)\t$green Version:$yellow ${V[$idx]}$pattern"
        done
        echo -ne $blue"\nEnter option: $pattern";read OPT_VERSION ; clear
        VRS=${V[$OPT_VERSION]}
    done
    clear
}

get_files() {
    Name_File=$(sudo curl https://repo.zabbix.com/zabbix/$VRS/debian/pool/main/z/zabbix-release/ -s | grep '<a href=' |cut -d'>' -f2 |grep zabbix-release_ |cut -d'<' -f1 |grep '.deb')
    until grep -E ^[0-9]+$ <<< $OPT_OS_VERSION; do
        cont=0
        for it in `echo $Name_File`
        do 
            NF[$cont]=$it
            cont=$(( $cont + 1))
        done 
        echo -e $green"Please choose an option.: \n$pattern"
        for ((idx=0; idx < ${#NF[@]}; idx++))
        do
            echo -e "> $yellow ($idx)\t$green OS Version:$yellow ${NF[$idx]} $pattern"
        done
        echo -ne $blue"\nEnter option: $pattern";read OPT_OS_VERSION ; clear
        OS_VRS=${NF[$OPT_OS_VERSION]}
    done
    clear
}

install_with_mysql() {
    echo -ne $green"Start zabbix download...$pattern"; sleep 1
    sudo wget https://repo.zabbix.com/zabbix/$VRS/debian/pool/main/z/zabbix-release/$OS_VRS 
    clear

    echo -ne $green"Managing packages ......$pattern"; sleep 1
    sudo dpkg -i $OS_VRS
    clear

    echo -ne $green"Updating repositories...$pattern"; sleep 1
    sudo apt update
    clear

    echo -ne $green"Installing the dependencies...$pattern"; sleep 1
    sudo apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent
    clear

    echo -ne $green"Enter a password for the mysql zabbix user: $pattern";read PASS_DB sleep 1
    echo -ne $green"Configuring the database...$pattern"; sleep 1
    sudo mysql -uroot -e "create database zabbix character set utf8 collate utf8_bin;"
    sudo mysql -uroot -e "grant all privileges on zabbix.* to zabbix@localhost identified by '$PASS_DB';"
    clear

    echo -ne $green"importing recent data schema...$pattern"; sleep 1
    sudo zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p $PASS_DB

    echo -ne $green"Setting password in zabbix_server.conf file...$pattern"; sleep 1
    sudo sed -i "s/DBPassword=/DBPassword=$PASS_DB/" /etc/zabbix/zabbix_server.conf
    clear

    echo -ne $green"Starting server and agent processes...$pattern"; sleep 1
    sudo systemctl restart zabbix-server zabbix-agent apache2
    sudo systemctl enable zabbix-server zabbix-agent apache2   

    clear
    echo -ne $green"Please open the file /etc/zabbix/apache.conf and change the line php_value date.timezone Europa/Riga to php_value date.timezone Continent/Status...$pattern"; sleep 1
    
}

dependencies
get_verions
get_files
install_with_mysql