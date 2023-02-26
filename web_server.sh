#!/bin/bash

log_generator () {

  if [ $1 != 0 ]; then
    logger "$(date +"%H:%M:%S %Y-%m-%d") [$2] - [$3] - ERROR - $1"
    echo "Error - Check /var/log/ for more info"
    exit
  else
      logger "$(date +"%H:%M:%S %Y-%m-%d") [$2] - [$3] - OK"
  fi
}



if [ "$EUID" -ne 0 ]
  then 
    echo "Execute with root"
  exit

fi

BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

install=false
service=false
pass1=false


while [ $pass1 = false ]; do
  
  clear
  echo
  echo

  echo "+--------------------------------------------------------+"
  echo "| / /      Select the the actions to perfomance      \ \ |"
  echo "+--------------------------------------------------------+"
  echo "|   1 - Install web services (Apache2, BBDD, PHP)        |"
  echo "|   2 - Create Hosting                                   |"
  echo "|   3 - All                                              |"
  echo "|                                                        |"
  echo "|   0 - Exit                                             |"
  echo "+--------------------------------------------------------+"

  echo
  echo -n 'Enter an option: '

  read options
  echo

  case $options in
    1)
      install=true
      pass1=true
      ;;
    2)
      service=true
      pass1=true
      ;;
    3)
      install=true
      service=true
      pass1=true
      ;;
    0)
      echo
      echo "Bye..."
      echo
      exit
      ;;
    *)
      echo -ne "${RED}Invalid option - Try again${NC}"
      read -s
      ;;
  esac
done

clear





if [ $install = true ]; then

  update=false
  upgrade=false
  apache=false
  php=false
  mariadb=false

  echo
  echo

  echo "+--------------------------------------------------------------+"
  echo "| / /          Select actions separated by spaces          \ \ |"
  echo "+--------------------------------------------------------------+"
  echo "|   1 - Update                                                 |"
  echo "|   2 - Upgrade                                                |"
  echo "|   3 - Install Apache2                                        |"
  echo "|   4 - Install PHP 7.4                                        |"
  echo "|   5 - Install & securize MariaDB                             |"
  echo "|   6 - Do all                                                 |"
  echo "|                                                              |"
  echo "|   0 - Exit                                                   |"
  echo "+--------------------------------------------------------------+"
  echo

  echo -n 'What I do?: '
  read options
  echo

  for option in $options
  do
    case $option in
      0)
        echo
        echo "Bye..."
        echo
        exit
        ;;
      1)
        update=true
        ;;
      2)
        upgrade=true
        ;;
      3)
        apache=true
        ;;
      4)
        php=true
        ;;
      5)
        mariadb=true
        ;;
      6)
        update=true
        upgrade=true
        apache=true
        php=true
        mariadb=true
        ;;
      *)
        echo -ne "${RED}Invalid option - Try again${NC}"
        ;;
    esac
  done

  if [ $update = true ]; then
      
    echo "Updating..."
    apt update -y > /dev/null 2>&1

    log_generator "$?" "" "update"
  fi

  if [ $upgrade = true ]; then
      
    echo "Upgrading..."
    apt upgrade -y > /dev/null 2>&1

    log_generator "$?" "" "upgrade"
  fi

  if [ $apache = true ]; then
      
    echo "Installing Apache2..."
    apt install apache2 openssl -y > /dev/null 2>&1

    log_generator "$?" "" "apache2-install"


    a2enmod ssl > /dev/null 2>&1

    log_generator "$?" "" "apache2-enmod_ssl"


    a2enmod rewrite > /dev/null 2>&1

    log_generator "$?" "" "apache2-enmod_rewrite"

    mkdir -p /etc/apache2/ssl/certs > /dev/null
    mkdir -p /etc/apache2/ssl/private > /dev/null

  fi

  if [ $php = true ]; then
      
    echo "Installing php7.4..."
    apt install php7.4 -y > /dev/null 2>&1

    log_generator "$?" "" "php-install"

    if [ $mariadb = true ]; then
      
      echo "Installing php-mysql..."
      apt install php-mysql -y > /dev/null 2>&1

      log_generator "$?" "" "php-install_php-mysql"
    fi

    if [ $apache = true ]; then
      
      echo "Installing libapache2-mod-php..."
      apt install libapache2-mod-php -y > /dev/null 2>&1

      log_generator "$?" "" "php-install_libapache2-mod-php"
    fi
  fi


  if [ $mariadb = true ]; then
      
    echo "Installing mariadb-server..."
    apt install mariadb-server -y > /dev/null 2>&1

    log_generator "$?" "" "mariadb-install"


    echo "Mariadb secure installation"

    echo -n "Enter the MariaDB password: "

    read -s mariadb_pass

    while [ -z $mariadb_pass ]; do
      read -s mariadb_pass
    done
    
    echo


  mysql -u root -p$mariadb_pass <<-EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$mariadb_pass';
DELETE FROM mysql.user WHERE User="";
DELETE FROM mysql.user WHERE User="root" AND Host NOT IN ("localhost", "127.0.0.1", "::1");
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db="test" OR Db="test\\_%";
FLUSH PRIVILEGES;
EOF

  log_generator "$?" "" "mariadb-secure_installation"

  echo

  fi



  if [ $service = true ]; then
    echo -n "Press any key to continue"
    waiting=true

    while [ $waiting = true ]; do
      read -t 3 -n 1
      if [ $? = 0 ] ; then
        waiting=false
      else
        echo
        echo -n "Waiting for the keypress"
      fi
    done
    clear
  fi

fi



if [ $service = true ]; then

  enter_domain () {
    clear
    echo
    echo

    echo "+--------------------------------------------------------------+"
    echo "| / /          Enter a valid name for the service          \ \ |"
    echo "+--------------------------------------------------------------+"
    echo "|                                                              |"
    echo "|   0 - Exit                                                   |"
    echo "+--------------------------------------------------------------+"
    echo
    echo

    if [ -n "$1" ]; then
      echo -e $1
    fi
    
    if [ -n "$2" ]; then
      echo -en $2
    fi


    correct_name=false

    validation="^([a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.)+[a-zA-Z]{2,}$"

    while [ $correct_name = false ]; do
      echo -n '~# '
      read service_name

      if [ $service_name = 0 ]; then
        echo
        echo "Bye..."
        echo
        exit
      fi

      if [[ "$service_name" =~ $validation ]]; then
        correct_name=true
      else

        enter_domain "$service_name ${RED} is not a correct name - Try again ${NC}" "Enter a valid service name "
      fi
    done


  }



  web_directory=false
  vh_http=false
  vh_https=false
  create_db=false

  enter_domain

  clear

  echo
  echo

  echo "+--------------------------------------------------------------+"
  echo "| / /          Select actions separated by spaces          \ \ |"
  echo "+--------------------------------------------------------------+"
  echo "|   1 - Create web directory for the service                   |"
  echo "|   2 - Create VHost HTTP for the service                      |"
  echo "|   3 - Create VHost HTTPS for the service                     |"
  echo "|   4 - Create DB for the service                              |"
  echo "|   5 - Do all                                                 |"
  echo "|                                                              |"
  echo "|   0 - Exit                                                   |"
  echo "+--------------------------------------------------------------+"
  echo

  echo -n 'What I do?: '
  read options
  echo


  for option in $options
  do
    case $option in
      0)
        echo
        echo "Bye..."
        echo
        exit
        ;;
      1)
        web_directory=true
        ;;
      2)
        vh_http=true
        ;;
      3)
        vh_https=true
        ;;
      4)
        create_db=true
        ;;
      5)
        web_directory=true
        vh_http=true
        vh_https=true
        create_db=true
        ;;
      *)
        echo -ne "${RED}Invalid option - Try again${NC}"
        ;;
    esac
  done


  if [ $web_directory = true ]; then

    dir=/var/www/$service_name

    if [ -d "$dir" ]; then
      enter_domain "$dir ${RED} directory alredy exists - Try again${NC}"
    else
      echo "Creating the web directory..."
      mkdir $dir > /dev/null 2>&1

      log_generator "$?" "$service_name" "web-create_directory"
      
      echo "Changing permissions..."
      chown -R $USER:www-data $dir > /dev/null 2>&1

      log_generator "$?" "$service_name" "web-directory-changing_permissions"

      echo "Site created by K-Script" > $dir/index.html
      echo "GITHUB" >> $dir/index.html
      
    fi  
  fi


  if [ $vh_http = true ] || [ $vh_https = true ]; then
    a2dissite 000-default > /dev/null

    vhost_http='<VirtualHost *:80>
    ServerName your_domain
    ServerAlias www.your_domain 
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/your_domain
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>'


    vhost_http=$(echo "$vhost_http" | sed "s/your_domain/$service_name/g")
      
    echo "Creating VHost HTTP..."
    echo "$vhost_http" > /etc/apache2/sites-available/$service_name.conf

    log_generator "$?" "$service_name" "vhost-create_http"

    echo "Enabling site..."
    
    a2ensite $service_name.conf > /dev/null 2>&1
    
    log_generator "$?" "$service_name" "vhost-enable_site"

    if [ $vh_https = false ]; then
      echo "Reloading Apache2..."

      systemctl reload apache2 > /dev/null 2>&1

      log_generator "$?" "$service_name" "vhost-realod_apache2"
    fi
  fi


  if [ $vh_https = true ]; then
      
    vhost_https='
    
# <VirtualHost *:443>
#     ServerAdmin webmaster@localhost
#     DocumentRoot /var/www/your_domain
#     ErrorLog ${APACHE_LOG_DIR}/error.log
#     CustomLog ${APACHE_LOG_DIR}/access.log combined
# 
#     SSLEngine on
#     SSLCertificateFile /etc/apache2/ssl/certs/cert-your_domain.pem
#     SSLCertificateKeyFile /etc/apache2/ssl/private/cert-your_domain.key
# </VirtualHost>'



    vhost_https=$(echo "$vhost_https" | sed "s/your_domain/$service_name/g")
      
    echo "Creating VHost HTTPS..."
    echo "$vhost_https" >> /etc/apache2/sites-available/$service_name.conf

    log_generator "$?" "$service_name" "vhost-create_https"

    echo "Reloading Apache2..."

    systemctl reload apache2 > /dev/null 2>&1

    log_generator "$?" "$service_name" "vhost-realod_apache2"

    echo
    echo -e "${RED} - IMPORTANT - ${NC}"
    echo
    echo "# If you want to acces to your site $service_name in HTTPS you have to:"
    echo "# Remove the comments of de VHost in /etc/apache2/sites-avaliable/$service_name.conf"
    echo "# Upload your cert to:"
    echo -e "# - ${BLUE}/etc/apache2/ssl/certs/cert-$service_name.pem${NC}"
    echo -e "# - ${BLUE}/etc/apache2/ssl/private/cert-$service_name.key${NC}"
    echo "# Reload apache by 'systemctl reload apache2' or '/etc/init.d/apache2 reload'"
    echo -e "${RED} - --- - ${NC}"
    echo

  fi


  if [ $create_db = true ]; then

    if [ -z "$mariadb_pass" ]; then
      echo -n "Enter the MySQL root password: "
      read -s mariadb_pass
      echo
    fi

    db_name=$(echo "$service_name" | sed -e "s/\.//g")
      
    echo "Creating the DB..."
    echo -e "The DB name is:${BLUE} $db_name ${NC}"

    db_usr_password=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()_+-=' | fold -w 12 | head -n 1)
   
    mysql -u root -p$mariadb_pass <<-EOF
create database $db_name;
create user 'usr_$db_name'@'localhost' identified by '$db_usr_password';
grant all privileges on $db_name.* to 'usr_$db_name'@'localhost' identified by '$db_usr_password' with grant option;
revoke delete, drop, create view, show view on *.* from 'usr_$db_name'@'localhost';
EOF

    echo -e "The username is:${BLUE} 'usr_$db_name'${NC}"
    echo -e "The password is:${BLUE} '$db_usr_password'${NC}"
    
    log_generator "$?" "$service_name" "bbdd-create_user"
  fi

fi
