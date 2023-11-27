#!/bin/bash

# Pfad zum SSH-Key
SSH_KEY=""

# Zielverzeichnis auf dem Host
DESTINATION_DIR=""

# Verzeichnis auf dem Raspberry Pi
REMOTE_DIR=""

# Überprüfen, ob der SSH-Schlüssel existiert
if [ ! -f "$SSH_KEY" ]; then
    echo "SSH-Schlüssel $SSH_KEY nicht gefunden."
    exit 1
fi

# IP-Adressen in ein Array laden
readarray -t ips < "ips.txt"

# Über jede IP-Adresse iterieren
for ip in "${ips[@]}"; do
    if [[ -z "$ip" ]]; then
        continue
    fi

    echo "Verbinde mit $ip..."

    # SSH-Befehl zum Erstellen einer Dateiliste im Remote-Verzeichnis und direkte Verarbeitung
    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            # Extrahiere den Dateinamen
            filename=$(basename "$file")

            # Füge die IP-Adresse zum Dateinamen hinzu
            new_filename="${ip//./_}_$filename"

            # Übertrage die Datei und benenne sie um
            if ! scp -i "$SSH_KEY" -o ConnectTimeout=10 "pi@$ip:$file" "$DESTINATION_DIR/$new_filename"; then
                echo "Fehler beim Übertragen der Datei $file von $ip."
            fi
        fi
    done < <(ssh -i "$SSH_KEY" -o ConnectTimeout=10 pi@"$ip" "find $REMOTE_DIR -name '*.bin'" 2>/dev/null)

    # Löschen aller .bin-Dateien im Remote-Verzeichnis
    ssh -i "$SSH_KEY" -o ConnectTimeout=10 pi@"$ip" "rm -f $REMOTE_DIR/*.bin" 2>/dev/null && echo "Alle .bin-Dateien auf $ip gelöscht." || echo "Fehler beim Löschen der Dateien auf $ip."

    echo "Dateien von $ip übertragen und gelöscht."
done

echo "Alle IPs aus ips.txt wurden bearbeitet."
