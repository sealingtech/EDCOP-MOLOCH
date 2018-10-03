# Configuring Moloch Script, uses default values. 
# Instead of editing these values, make changes to /etc/config.ini 

/data/moloch/bin/Configure << EOF
$INTERFACE
no
$ES_HOST:9200
$CLUSTER_PW
EOF

