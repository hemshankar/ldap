========================================================LDAP installation==================================================================

                                           ##############################Server installation################################
#check what all packages are present
rpm -qa | grep openldap
#install all the necessary packages in server
sudo yum install openldap*
#check again to verify what all installed
rpm -qa | grep openldap
#generate password hash to be added to the ldap server
slappasswd
#this will ask for a password, on entring the password it will give a hash something like {SSHA}Qhev8j4dci4Dti0e31WnOKHcUL+Qha6S
#edit the conf files
sudo vi /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{2\}bdb.ldif
#change 
# olcSuffix: dc=my-domain,dc=com 
#to 
# olcSuffix: dc=informatica,dc=com
# olcRootDN: cn=Manager,dc=my-domain,dc=com
#to
# olcRootDN: cn=Manager,dc=informatica,dc=com
#add following line to the file
# olcRootPW: {SSHA}Qhev8j4dci4Dti0e31WnOKHcUL+Qha6S
sudo vi /etc/openldap/slapd.d/cn\=config/olcDatabase\=\{1\}monitor.ldif
#change 
# dn.base="cn=manager,dc=my-domain,dc=com"
#to
# dn.base="cn=Manager,dc=informatica,dc=com"

#run updatedb to create/update the database used by locate`
sudo updatedb
#copy the DB_CONFIG.example file to /var/lib/ldap so that ldap can use it
sudo cd /usr/share/openldap-servers/
sudo cp DB_CONFIG.example /var/lib/ldap/DB_CONFIG

#change the owner ship of /var/lib/ldap to ldap.ldap
sudo chown -R ldap.ldap /var/lib/ldap/
#check if /var/lib/ldap/ permissions
ls -ld /var/lib/ldap/
#check all the configurations are correct 
sudo slaptest -u
#start the ldap server
sudo service slapd start
#check if the process existing
ps -ef | grep slapd
#check if ldap starte in default port i.e. 389
netstat -nat | grep 389
#try using ldap 
sudo ldapsearch -x -b " dc=informatica,dc=com"
 
 

                                ##############################Migrate host users to LDAP################################

#check if the migration package is installed
rpm -qa | grep migrationtools
#if not installed
sudo yum install migrationtools -y
#go to /usr/share/migrationtools/
cd /usr/share/migrationtools/
sudo vi migrate_common.ph
#$EXTENDED_SCHEMA = 0; #set this to 1
#$NAMINGCONTEXT{'group'} = "ou=Group"; #change Group to Groups
#Update following accordingly
# Default DNS domain
$DEFAULT_MAIL_DOMAIN = "informatica.com";
# Default base
$DEFAULT_BASE = "dc=informatica,dc=com";

sudo ./migrate_base.pl > /root/ldap/base.ldif
#to check
ls /root/ldap/
#create 3 users and a home folder for them 
sudo useradd user1
sudo useradd user2
sudo useradd user3
sudo passwd user1
sudo passwd user2
sudo passwd user3
sudo mkdir /home/ldap/user1
sudo mkdir /home/ldap/user2
sudo mkdir /home/ldap/user3
sudo chown -R user1 /home/user1
sudo chown -R user2 /home/user2
sudo chown -R user3 /home/user3
getent passwd | tail -n 3 > /root/ldap/users
getent shadow | tail -n 3 > /root/ldap/passwords
getent group | tail -n 3 > /root/ldap/groups
sudo vim migrate_passwd.pl # change line 188 change /etc/shadow to /root/ldap/passwords
./migrate_passwd.pl /root/ldap/users > /root/ldap/users.ldif
./migrate_group.pl /root/ldap/groups > /root/ldap/groups.ldif
ls /root/ldap
cd /root/ldap
#add the base services,users and groups
ldapadd -x -W -D "cn=Manager,dc=informatica,dc=com" -f base.ldif
ldapadd -x -W -D "cn=Manager,dc=informatica,dc=com" -f users.ldif
ldapadd -x -W -D "cn=Manager,dc=informatica,dc=com" -f groups.ldif
#test the inserted data
ldapsearch -x -b "dc=informatica,dc=com" | less
ldapsearch -x -b "dc=informatica,dc=com" | grep user1
slapcat -v
 
 
                                   ####################################### Install phpLDAPAdmin to access ldap from browser ##########################################
#install phpldapadmin
sudo yum install php php-cli php-common php-ldap -y
sudo yum install phpldapadmin -y

#configure phpadmin
sudo vim /etc/phpldapadmin/config.php
#uncomment $server->setvalue('login','attr','dn')
#comment $server->setvalue('login','attr','uid')
sudo vim /etc/httpd/conf.d/phpldapadmin.conf
#modify 'Allow from 127.0.0.0' to 'Allow from 127.0.0.0 10.140.75.0/24'
#Restart the ldap server
sudo service httpd restart
# access the server at http://<your ip>/ldapadmin
#login using username: cn=Manager,dc=informatica,dc=com and password which you provided for slappasswd