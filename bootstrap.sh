#!/bin/bash

##########################################################################
#                                                                        #
#                                                                        #
#      Bootstrap to setup and configure an NGINX reverse proxy on        #
#      RHEL on EC2 														 #
#                                                                        #
#      Sugasini - Nov 2024
#                                                                        #
##########################################################################
                                                                       
#Dot source the environment variables
echo "[DEBUG MESSAGE]:  Copying environment variables file"
cp -r /root/payload/env.sh /usr/local/bin/env.sh
if [ $? -ne 0 ];
then
  echo "Failed to copy environment variables file"
  exit 1
fi

echo "[DEBUG MESSAGE]:  Setting permissions on script"
chmod +x /usr/local/bin/env.sh
if [ $? -ne 0 ];
then
  echo "Failed to chmod env.sh"
  exit 1
fi
echo "[DEBUG MESSAGE]:  Setting permissions on env script"
chmod 777 /usr/local/bin/env.sh
if [ $? -ne 0 ];
then
  echo "Failed to set permissions to 750"
  exit 1
fi

echo "[DEBUG MESSAGE]:  Sourcing script"
source /usr/local/bin/env.sh
if [ $? -ne 0 ];
then
  echo "Failed to source the env.sh into the current bash sessions"
  exit 1
fi

#Resize the log location
echo "[DEBUG MESSAGE]:  Resizing /dev/xvdh"
resize2fs /dev/xvdh 
if [ $? -ne 0 ];
then
  echo "Failed to resize /dev/xvdh"
  exit 1
fi

source /root/context
if [ $? -ne 0 ];
then
  echo "Failed to source the QCP pipeline context file "
  exit 1
fi

#install required packages
yum install vim wget mlocate tmux -y
if [ $? -ne 0 ];
then
  echo "Failed to install vim wget mlocate screen "
  exit 1
fi

# Go Go Gadget NGINX

echo "Install nginx module and enable module"
dnf module disable php -y
dnf module enable nginx:1.24 -y
dnf install nginx nginx-mod-stream -y

# Install our own tools that make troubleshooting easy/possible
echo "[DEBUG MESSAGE]:  Updating packages in repo"
yum install mc vim-enhanced tmux nano wget dstat nmap-ncat gdb mlocate pcre2 -y
if [ $? -ne 0 ];
then
  echo "Failed to install tools to troubleshoot the server using YUM"
  exit 1
fi

# Enabling the file descriptors limit for nginx
echo "[DEBUG MESSAGE]:  Increasing the file descriptor limits"
  echo "
  # Increasing the file descriptior limit for nginx
  root       soft    nofile  10000
  root       hard    nofile  3000" >> /etc/security/limits.d/30-nofile.conf
if [ $? -ne 0 ];
then
  echo "Failed to increase the file descriptor limits"
  exit 1
fi

# make SELINUX behave
setsebool -P httpd_can_network_connect on
if [ $? -ne 0 ];
then
  echo "Failed to configure SELinux to allow network loopback httpd_can_network_connect=1 "
  exit 1
fi

echo "To display the current status of the httpd_can_network_connect boolean"
getsebool httpd_can_network_connect

semodule -i /root/payload/mynginx.pp
if [ $? -ne 0 ];
then
  echo "Could not apply custom SELinux policy /root/payload/mynginx.pp "
  exit 1
fi

echo "Check Nginx Configuration"
sudo nginx -t

echo "Adding labels to port 3000"
semanage port -a -t http_port_t -p tcp 3000

echo "Start nginx service"
systemctl enable nginx 
systemctl start nginx 
if [ $? -ne 0 ];
then
 echo "Failed to start the nginx service "
 exit 1
fi

updatedb

if [ $? -ne 0 ];
	then
	echo "Something went wrong updating the mlocate database, failing build"
fi

source /root/payload/functions.sh
securePayloadFiles

# Go home
cd ~

maySOEFix
resizeDisks
createSrmUser
