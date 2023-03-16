#variables
s3_bucket=upgrad-tejaswi
name="tejaswi"

#update ubuntu repositories
sudo apt get update -y

#check if apache2 installed 
apache2 = $(dpkg --get-selections apache2 | awk '{print $2}')
if [ apache2 != $install ];
then
	sudo apt install apache2 -y
fi

#Ensure apache2 is running
running = $(sudo systemctl status apache2 | grep "active" | awk '{print $3}' | tr -d '()')

if [ running != $running ];
then
	systemctl enable apache2
fi

#apache2 service is enabled

enabled = $(systemctl is-enabled apache2 | grep "enabled")

if [ enabled != $enabled ];
then
	systemctl enable apache2
fi

#creating tar file out of accesslogs and errorlogs

cd /var/log/apache2/
timestamp=$(date '+%d%m%Y-%H%M%S')
tar -cf /tmp/${name}-httpd-logs-${timestamp}.tar .*log

#copy logs to s3 bucket

if [[ -f /tmp/${name}-httpd-logs-${timestamp}.tar ]];
then
	aws s3 cp /tmp/${name}-httpd-logs-${timestamp}.tar s3://${s3_bucket}/${name}-httpd-logs-${timestamp}.tar
fi

#checking inventory file exists 
docroot="/var/www/html"

if [[ -f $(inventory.html/$docroot) ]]; then
	echo -e 'Log Type\t-\tTime Created\t-\tType\t-\tSize' > ${docroot}/inventory.html
fi

#inserting log files into the file

if [[ -f ${docroot}/inventory.html ]]; then
	#statements
    size=$(du -h /tmp/${name}-httpd-logs-${timestamp}.tar | awk '{print $1}')
	echo -e "httpd-logs\t-\t${timestamp}\t-\ttar\t-\t${size}" >> ${docroot}/inventory.html
fi


# Create a cron job that runs service every minutes/day
if [[ ! -f /etc/cron.d/automation ]]; then
	#statements
	echo "* * * * * root /root/automation.sh" >> /etc/cron.d/automation
fi
