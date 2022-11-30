#!/command/with-contenv sh
set -e;

echo "[fcgiwrap] Starting fcgiwrap"
/usr/bin/spawn-fcgi  -s /var/run/fcgiwrap.socket -P /var/run/fcgiwrap.pid -u www-data -g www-data -U www-data -G www-data -n -- /usr/sbin/fcgiwrap