#!/bin/bash
dir=$(dirname "$(realpath "$0")")
quelle=/path/to/source
backup=/path/to/destination/
nosave=$dir/exclude.txt

last_backup_file="$dir/.last_backup_path"
if [ -f "$last_backup_file" ]; then
  last_backup_path=$(cat "$last_backup_file")
else
  last_backup_path=""
fi


touch $nosave

# Datum ermitteln:
wochentag=$(date +"%a") # %a = Wochentag in Kurzform als Text. Beachtet dabei, dass der Inhalt der Variable von der eingestellten Sprache im System abhängig ist.
tag=$(date +"%d")       # %d = Tagdatum als zweistellige Zahl.
monat=$(date +"%m")     # %m = Monatsdatum als zweistellige Zahl.

# Backup Funktion definieren:
function backup ()
{

 start_time=$(date +%s)
 backup_path="$backup/$1/"

 echo >"$backup/_letzte_Sicherung.txt"
 echo "-----------------------------------------------" >> "$backup/_letzte_Sicherung.txt"
 echo "Starting backup: $(date "+%Y-%m-%d %H:%M:%S")" >> "$backup/_letzte_Sicherung.txt"
 echo "Backup Path: $backup_path" >> "$backup/_letzte_Sicherung.txt"
 echo "Source Path: $quelle" >> "$backup/_letzte_Sicherung.txt"
 echo "Link Destionation used: $last_backup_path" >> "$backup/_letzte_Sicherung.txt"
 echo "-----------------------------------------------" >> "$backup/_letzte_Sicherung.txt"
 echo -e '\n' >>"$backup/_letzte_Sicherung.txt"



 if [ -n "$last_backup_path" ]; then
  link_dest_option="--link-dest=$last_backup_path"
 else
  link_dest_option=""
 fi

 rsync -rtpgov --delete --checksum -hh --stats --exclude-from="$nosave" $link_dest_option "$quelle/" "$backup/$1/" >>"$backup/_letzte_Sicherung.txt" 2>&1
 rsync -rtpgov --delete --checksum -hh --stats --exclude-from="$nosave" --link-dest="/mnt/fivem/OldScripts/" "/mnt/fivem/OldScripts/" "$backup/$1/OldScripts/" 2>&1
 mysqldump --single-transaction -u fivem -pnewaera -h 49.13.172.228 fivem>"$backup/$1/sql_backup_$(date "+%Y-%m-%d").sql" 


 end_time=$(date +%s)
 duration=$((end_time - start_time))
 backup_size=$(du -sh "$backup_path" | cut -f1)

 echo -e '\n'>> "$backup/_letzte_Sicherung.txt"
 echo "-----------------------------------------------" >> "$backup/_letzte_Sicherung.txt"
 echo "Backup completed: $(date "+%Y-%m-%d %H:%M:%S")" >> "$backup/_letzte_Sicherung.txt"
 echo "Duration: $duration seconds" >> "$backup/_letzte_Sicherung.txt"
 echo "Backup Size: $backup_size" >> "$backup/_letzte_Sicherung.txt"
 echo "-----------------------------------------------" >> "$backup/_letzte_Sicherung.txt"

 mv $backup/_letzte_Sicherung.txt $backup/$1/_letzte_Sicherung_$(date "+%Y-%m-%d").txt
 echo "$backup/$1" > $last_backup_file
 }

## tägliche Sicherung (Montag - Sonntag):
# Nur wenn der Tag nicht der 01, 09, 16 oder 24 ist wird hier gesichert - sonst wird eine Wochen- oder Monatssicherung durchgeführt:
if [[ $tag != 01 && $tag != 09 && $tag != 16 && $tag != 24 ]]; then
 # und wenn Wochentag = ... dann Sicherung im Unterordner vom Wochentag:
 case "$wochentag" in Mon|Tue|Wed|Thu|Fri|Sat|Sun) backup $wochentag ;; esac
 # Hinweis: Bei einem Betriebssystem mit englischer Spracheinstellung muss man die Wochentagsnamen wie folgt verändern: 'Mon|Tue|Wed|Thu|Fri|Sat|Sun'.
fi

## Wochensicherungen:
# Hinweis:
# 1. Woche ist die Monatssicherung.

# 2. Woche (9. Tag):
case "$tag" in 09) backup 09 ;; esac

# 3. Woche (16. Tag):
case "$tag" in 16) backup 16 ;; esac

# 4. Woche (24. Tag):
case "$tag" in 24) backup 24 ;; esac

## Monatssicherungen:
# wenn gerader Monat (Mg):
case "$monat" in 02|04|06|08|10|12)
 # und wenn 1.ter im Monat:
 case "$tag" in 01)
 backup Mg
 ;; esac
;; esac

# wenn ungerader Monat (Mu):
case "$monat" in 01|03|05|07|09|11)
 # und wenn 1.ter im Monat:
 case "$tag" in 01)
 backup Mu
 ;; esac
;; esac
