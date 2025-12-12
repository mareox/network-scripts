#!/bin/bash
####################################
#
# Grab certificates and keys from the NGINX and upload them to the firewall and commit
#
####################################

exec 2>> /var/log/cert_api.log

recipient="<REDACTED>"
user="<REDACTED>"
pass="<REDACTED>"
host="<REDACTED>"
domain="<REDACTED>"
fqdn="${host}.${domain}"
firewall="<REDACTED>"

read line

if [[ $line =~ "Writing certificate to" ]]; then

	cert_path="$(sed -E 's/.*Writing certificate to (.*\.pem)\.$/\1/' <<<$line)"
	cert_dir="${cert_path%/*}"
	cert_name="${cert_dir##*/}"
	cert_file="${cert_path##*/}"
	cert_ver="${cert_file//[^0-9]/}"
	cert_staging="/root/cert_staging/${cert_name}"

	mkdir ${cert_staging}
	scp root@${fqdn}:${cert_dir}/*${cert_ver}.pem ${cert_staging}
	output="Gathered new certificates and key from DMZ:\n"
	output+="$(ls -og ${cert_staging}/*${cert_ver}.pem)"

	cert_ca_cn=$(openssl x509 -noout -subject -in ${cert_staging}/chain${cert_ver}.pem -nameopt multiline | grep commonName | awk '{print $3}')
	cat ${cert_staging}/cert${cert_ver}.pem ${cert_staging}/privkey${cert_ver}.pem > ${cert_staging}/cert_privkey${cert_ver}.pem

	api_key=$(curl -k "https://${firewall}/api/?type=keygen&user=${user}&password=${pass}" | sed -E 's/.*<key>(.*)<\/key>.*/\1/')

	output+="\n\nUploading CA cert to firewall:\n"
	output+=$(curl -F "file=@${cert_staging}/chain${cert_ver}.pem" "https://${firewall}/api/?key=${api_key}&type=import&category=certificate&certificate-name=LetsEncrypt-${cert_ca_cn}&format=pem")

	output+="\n\nUploading new cert amd key to firewall:\n"
	output+=$(curl -F "file=@${cert_staging}/cert_privkey${cert_ver}.pem" "https://${firewall}/api/?key=${api_key}&type=import&category=keypair&certificate-name=${cert_name}&format=pem&format=pem&passphrase=''")

	output+="\n\nCommitting changes:\n"
	output+=$(curl -k "https://${firewall}/api/?key=${api_key}&type=commit&cmd=<commit><partial><admin><member>${user}</member></admin></partial></commit>")

	output+="\n\nCleaning up:\n"
	output+=$(rm -v ${cert_staging}/cert_privkey${cert_ver}.pem)
	output+="\n"
	output+=$(rm -v ${cert_staging}/privkey${cert_ver}.pem)

	# Send notification
	(
		echo "To: ${recipient}"
		echo "Subject: MX-FW: Certificate for ${cert_name} Updated"
		echo "Content-Type: text/html"
		echo "MIME-Version: 1.0"
		echo "<PRE>"
		echo -e "$output"
		echo "</PRE>"
	) | sendmail -t
fi	