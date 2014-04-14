#! /bin/bash
#This program is free software: you can redistribute it and/or modify it 
#under the terms of the GNU General Public License as published by the 
#Free Software Foundation, either version 2 of the License, or (at your option) 
#any later version.
#
#This program is distributed in the hope that it will be useful, but WITHOUT ANY 
#WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
#See the GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License along with this program. 
#If not, see http://www.gnu.org/licenses/.

LOG_FILE=`mktemp`
DOMAIN_NAME=""
DB_EXT="_db"


if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root" 1>&2
	echo "Use sudo ./solution.sh to run this script" 1>&2
	exit 1
fi

touch $LOG_FILE
chmod 777 $LOG_FILE

clear
echo "		Welcome to WordPress Installer"
echo "	This is simple shell scripts which will configure"
echo "	Ngnix, MySQL and PHP5 for latest version of WordPress"
echo "	This scripts also writes log to file $LOG_FILE"

echo "Step -1:"
echo "	Wait while Installing Nginx MySQL and PHP5..."
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
apt-get -y install nginx mysql-server php5 php5-fpm > $LOG_FILE 2>&1 

if [ $? -ne 0 ]; then
	echo "ERROR: Failed to install Required dependencies, Please check logfile $LOG_FILE" 1>&2
	exit 1
fi

echo "Step -1 Completed. Nginx, MySQL and PHP5 installtion Done"
echo ""
echo ""

echo "Step -2:"
echo "	Configuring Nginx..."
echo -n "Please Enter Domain Name:"
read DOMAIN_NAME
while [ -z "$DOMAIN_NAME" ];do
	echo -n "Domain must not be null, Please Reenter:"
	read DOMAIN_NAME
done

if [ -d "/var/www/$DOMAIN_NAME" ];then
	echo "ERROR: Domain Name Allready Exists, Quiting" 1>&2
	exit 1
fi

echo "127.0.0.1	$DOMAIN_NAME" >> /etc/hosts

cat <<CONFIG > /etc/nginx/sites-available/$DOMAIN_NAME
server {
        listen   80;


        root /var/www/$DOMAIN_NAME;
        index index.php index.html index.htm;

        server_name $DOMAIN_NAME;

        location / {
                try_files \$uri \$uri/ /index.php?q=\$uri&\$args;
        }

        error_page 404 /404.html;

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
              root /usr/share/nginx/www;
        }

        location ~ \.php$ {
                try_files \$uri =404;
                fastcgi_pass unix:/var/run/php5-fpm.sock;
                fastcgi_index index.php;
                include fastcgi_params;
                 }
        

}
CONFIG

ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled/$DOMAIN_NAME
service nginx restart > $LOG_FILE 2>&1 
service php5-fpm restart > $LOG_FILE 2>&1 
echo "Step -2 Completed"

echo ""
echo ""

echo "Step -3"
echo "	Wait while downloading Wordpress from http://wordpress.org/latest.zip..."
wget http://wordpress.org/latest.zip > $LOG_FILE 2>&1 
if [ $? -ne 0 ];then
	echo "ERROR: Failed to get file http://wordpress.org/latest.zip, Please check log" 1>&2
	exit 1
fi
echo "Step -3 Completed. Downloading successfull"
echo ""
echo ""

echo "Step -4:"
echo "	UnZipping Wordpress.."
unzip -o latest.zip > $LOG_FILE 2>&1 

if [ $? -ne 0 ];then
	echo "ERROR: Failed to unzip latest.zip, Please check log" 1>&2
	exit 1
fi

echo "Step -4 Completed. Unzipping Successfull"

echo ""
echo ""

echo "Step -5:"
echo "	Configuring WordPress..."

mkdir /var/www/$DOMAIN_NAME
cp -r wordpress/* /var/www/$DOMAIN_NAME
rm latest.zip
rm -rf wordpress
sudo chown -R www-data:www-data /var/www/$DOMAIN_NAME
chmod -R 755 /var/www

cat <<WP_CONFIG >/var/www/$DOMAIN_NAME/wp-config.php
<?php
/**
 * The base configurations of the WordPress.
 *
 * This file has the following configurations: MySQL settings, Table Prefix,
 * Secret Keys, WordPress Language, and ABSPATH. You can find more information
 * by visiting {@link http://codex.wordpress.org/Editing_wp-config.php Editing
 * wp-config.php} Codex page. You can get the MySQL settings from your web host.
 *
 * This file is used by the wp-config.php creation script during the
 * installation. You don't have to use the web site, you can just copy this file
 * to "wp-config.php" and fill in the values.
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', '$DOMAIN_NAME$DB_EXT');

/** MySQL database username */
define('DB_USER', 'wordpressuser');

/** MySQL database password */
define('DB_PASSWORD', 'password');

/** MySQL hostname */
define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each a unique
 * prefix. Only numbers, letters, and underscores please!
 */
\$table_prefix  = 'wp_';

/**
 * WordPress Localized Language, defaults to English.
 *
 * Change this to localize WordPress. A corresponding MO file for the chosen
 * language must be installed to wp-content/languages. For example, install
 * de_DE.mo to wp-content/languages and set WPLANG to 'de_DE' to enable German
 * language support.
 */
define('WPLANG', '');

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
WP_CONFIG

echo "Step -5 Completed. Configuration Successfull"
echo ""
echo ""
echo "Step -6:"
echo "	Creating MySQL database..."
mysql --user=root --password=gaurav123 --execute="CREATE DATABASE \`$DOMAIN_NAME$DB_EXT\`; grant all on \`$DOMAIN_NAME$DB_EXT\`.* to 'wordpressuser'@'localhost' identified by 'password'; FLUSH PRIVILEGES;" > $LOG_FILE 2>&1 

if [ $? -ne 0 ];then
	echo "ERROR: Failed to Create Database, Please check log" 1>&2
	exit 1
fi
echo "Step -7 Completed."
echo ""
echo ""
echo "Script Executed Successfully. Please open http://$DOMAIN_NAME in your faviourate browser to access your WordPress Site"
exit 0;
