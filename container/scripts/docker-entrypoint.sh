#!/bin/bash
# Script to initialize Moloch, add a user, and run the services

# Check to see if Elasticsearch is reachable
echo "Trying to reach Elasticsearch..."
until $(curl --output /dev/null --fail --silent -X GET "$ES_HOST:9200/_cat/health?v"); do
  echo "Couldn't get Elasticsearch at $ES_HOST:9200, are you sure it's reachable?"
  sleep 5
done

# Check to see if Moloch has been installed before to prevent data loss
STATUS5=$(curl -X --head "$ES_HOST:9200/sequence_v1" | jq --raw-output '.status')
STATUS6=$(curl -X --head "$ES_HOST:9200/sequence_v2" | jq --raw-output '.status')

# Initialize Moloch if this is the first install
if [ "$STATUS5" = "404" ] && [ "$STATUS6" = "404" ]
then
  echo "Initializing Moloch indices..."
  echo INIT | /data/moloch/db/db.pl http://$ES_HOST:9200 init
  /data/moloch/bin/moloch_add_user.sh admin "Admin User" $ADMIN_PW --admin
  /data/moloch/bin/moloch_update_geo.sh
fi

chmod a+rwx /data/moloch/raw /data/moloch/logs

# Deploy Moloch as both a sensor and viewer node
if [ "$SENSOR" = "true" ] && [ "$VIEWER" = "true" ]
then
  echo "Starting Moloch capture and viewer..."
  /data/moloch/bin/moloch_config_interfaces.sh
  cd /data/moloch
  nohup /data/moloch/bin/moloch-capture -c /data/moloch/etc/config.ini >> /data/moloch/logs/capture.log 2>&1 &
  cd /data/moloch/viewer
  /data/moloch/bin/node viewer.js -c /data/moloch/etc/config.ini >> /data/moloch/logs/viewer.log 2>&1
# Sensor only node
elif [ "$SENSOR" = "true" ] 
then
  echo "Starting Moloch capture..."
  /data/moloch/bin/moloch_config_interfaces.sh
  cd /data/moloch
  /data/moloch/bin/moloch-capture -c /data/moloch/etc/config.ini >> /data/moloch/logs/capture.log 2>&1
# Viewer only node 
elif [ "$VIEWER" = "true" ]
then
  echo "Starting Moloch viewer..."
  cd /data/moloch/viewer
  /data/moloch/bin/node viewer.js -c /data/moloch/etc/config.ini >> /data/moloch/logs/viewer.log 2>&1
# Error
else
  echo "Both SENSOR and VIEWER cannot be set to false, exiting..."
  exit
fi

