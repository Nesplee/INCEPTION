#!/bin/bash

useradd -m -d /var/www/html/wordpress -s /bin/bash $FTP_USER

echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

mkdir -p /var/run/vsftpd/empty

exec vsftpd /etc/vsftpd.conf
