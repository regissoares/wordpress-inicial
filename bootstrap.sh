#!/usr/bin/env bash

DBHOST=localhost
DBNAME=wordpress
DBUSER=wordpress
DBPASSWORD=123

echo -e "\n-- Iniciando instalação --\n"

echo -e "\n-- Atualizando pacotes --\n"
apt-get -qq update

echo -e "\n-- Instalando pacotes essenciais --\n"
apt-get -y install build-essential python-software-properties >> /vagrant/build.log 2>&1

echo -e "\n-- Adicionando repositório do Apache --\n"
add-apt-repository -y ppa:ondrej/apache2 >> /vagrant/build.log 2>&1

echo -e "\n-- Atualizando pacotes --\n"
apt-get -qq update

echo -e "\n-- Instalando Apache --\n"
apt-get -y install apache2 >> /vagrant/build.log 2>&1

echo -e "\n-- Habilitando mod-rewrite --\n"
a2enmod rewrite >> /vagrant/build.log 2>&1

echo -e "\n-- Configurando Apache --\n"
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

echo -e "\n-- Adicionando repositório do MySQL --\n"
add-apt-repository -y ppa:ondrej/mysql-5.5 >> /vagrant/build.log 2>&1

echo -e "\n-- Atualizando pacotes --\n"
apt-get -qq update

echo -e "\n-- Instalando MySQL --\n"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBPASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBPASSWORD"
apt-get -y install mysql-server-5.5 >> /vagrant/build.log 2>&1

echo -e "\n-- Criando banco de dados e configurando usuário --\n"
mysql -uroot -p$DBPASSWORD -e "CREATE DATABASE $DBNAME"
mysql -uroot -p$DBPASSWORD -e "grant all privileges on $DBNAME.* to '$DBUSER'@'$DBHOST' identified by '$DBPASSWORD'"

echo -e "\n-- Executando scripts no banco de dados --\n"
mysql -u$DBUSER -p$DBPASSWORD $DBNAME < /vagrant/scripts.sql

echo -e "\n-- Adicionando repositório do PHP --\n"
add-apt-repository -y ppa:ondrej/php >> /vagrant/build.log 2>&1

echo -e "\n-- Atualizando pacotes --\n"
apt-get -qq update

echo -e "\n-- Instalando PHP --\n"
apt-get -y install php7.0 libapache2-mod-php7.0 php7.0-mysql php7.0-cli php7.0-json php7.0-mbstring php7.0-xml >> /vagrant/build.log 2>&1

echo -e "\n-- Configurando PHP --\n"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/apache2/php.ini

echo -e "\n-- Adicionando repositório do phpMyAdmin --\n"
add-apt-repository -y ppa:nijel/phpmyadmin >> /vagrant/build.log 2>&1

echo -e "\n-- Atualizando pacotes --\n"
apt-get -qq update

echo -e "\n-- Instalando phpMyAdmin --\n"
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWORD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"
apt-get -y install phpmyadmin >> /vagrant/build.log 2>&1

if [ ! -d /vagrant/public_html ]; then
  echo -e "\n-- Baixando WordPress --\n"
  wget https://br.wordpress.org/latest-pt_BR.tar.gz >> /vagrant/build.log 2>&1

  echo -e "\n-- Configurando WordPress --\n"
  tar -xzvf ./latest-pt_BR.tar.gz >> /vagrant/build.log 2>&1
  mv ./wordpress /vagrant/public_html
  cp /vagrant/public_html/wp-config-sample.php /vagrant/public_html/wp-config.php
  sed -i "s/define('DB_NAME', .*/define('DB_NAME', '$DBNAME');/" /vagrant/public_html/wp-config.php
  sed -i "s/define('DB_USER', .*/define('DB_USER', '$DBUSER');/" /vagrant/public_html/wp-config.php
  sed -i "s/define('DB_PASSWORD', .*/define('DB_PASSWORD', '$DBPASSWORD');/" /vagrant/public_html/wp-config.php
  sed -i "s/define('DB_HOST', .*/define('DB_HOST', '$DBHOST');/" /vagrant/public_html/wp-config.php
  rm ./latest-pt_BR.tar.gz
fi

echo -e "\n-- Configurando diretórios raiz --\n"
rm -rf /var/www/html
ln -fs /vagrant/public_html /var/www/html
ln -fs /usr/share/phpmyadmin /var/www/html/phpmyadmin

echo -e "\n-- Reiniciando Apache --\n"
service apache2 restart >> /vagrant/build.log 2>&1
