#!/bin/sh

# need jq and curl to be installed

[ ! -f .env ] || export $(sed 's/#.*//g' .env | xargs)

count=`curl -s -X GET \
 -H "Authorization: TOKEN $NETBOX_TOKEN" \
 -H "Accept: application/json" \
 https://${NETBOX_HOST}/api/dcim/devices.json | jq -e '.count'`

if [ "$?" -eq "0" ]
then
  echo "netbox api: OK"
else
  echo "netbox api: FAIL"
fi

echo ""
