#!/bin/bash

# Pfad zur Datei mit den IP-Adressen
IP_FILE=""

# Pfad zum SSH-Privatschlüssel
KEY_FILE=""

# Überprüfen, ob die IP-Datei existiert
if [ ! -f "$IP_FILE" ]; then
    echo "Datei $IP_FILE nicht gefunden."
    exit 1
fi

# Überprüfen, ob der SSH-Schlüssel existiert
if [ ! -f "$KEY_FILE" ]; then
    echo "SSH-Schlüssel $KEY_FILE nicht gefunden."
    exit 1
fi

# Einlesen der IP-Adressen aus der Datei und Ausführung der Befehle für jede IP
cat "$IP_FILE" | while read -r ip; do
    if [[ -z "$ip" ]]; then
        continue
    fi

    echo "Verbindung zu $ip..."

    # SSH-Befehl zum Sichern der aktuellen Crontab, Erstellen des Ordners, Bearbeiten der crontab des Root-Benutzers und Neustarten von Tomcat
    ssh -i "$KEY_FILE" -o ConnectTimeout=10 pi@$ip "
        DATE=\$(date +'%Y%m%d%H%M%S');
        sudo crontab -l > ~/crontab_backup_\$DATE;
        sudo mkdir -p /var/log/tomcat8;
        sudo chmod 777 /var/log/tomcat8;
        sudo crontab -l | grep -v '/var/log' | { cat; echo '0 0 * * * rm /var/log/tomcat8/* && echo > /var/log/syslog && echo > /var/log/auth.log && echo > /var/log/kern.log && echo > /var/log/messages'; } | sudo crontab -;
        sudo service tomcat8 restart
    " && echo "Crontab-Backup erstellt, Ordner /var/log/tomcat8 erstellt, Crontab für $ip als Root-Benutzer aktualisiert und Tomcat neugestartet." || echo "Fehler bei der Bearbeitung von $ip"
done

echo "Alle IPs aus $IP_FILE wurden bearbeitet."