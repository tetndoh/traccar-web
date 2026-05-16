#!/bin/bash
# init-users.sh
# This script initializes the default admin password and creates a mockup user for GeoNeo.
# It interacts with the Traccar Engine API.

API_URL="http://localhost:80/api"
ADMIN_EMAIL="admin"
ADMIN_OLD_PASS="admin"
ADMIN_NEW_EMAIL="admin@geoneo.com"
ADMIN_NEW_PASS="admin1234"

USER_EMAIL="user@geoneo.com"
USER_PASS="user1234"
USER_NAME="Demo User"

echo "Waiting for Traccar API to become available..."
until curl --output /dev/null --silent --head --fail "$API_URL/server"; do
    printf '.'
    sleep 2
done
echo " API is up!"

echo "1. Updating default Admin user..."
# We first get the admin user object
ADMIN_JSON=$(curl -s -u "$ADMIN_EMAIL:$ADMIN_OLD_PASS" -H "Accept: application/json" "$API_URL/users" | grep -o '{[^{]*"email":"admin"[^}]*}' || echo "")

if [ -n "$ADMIN_JSON" ]; then
    ADMIN_ID=$(echo "$ADMIN_JSON" | grep -o '"id":[0-9]*' | cut -d: -f2)
    # Update admin credentials
    UPDATE_ADMIN_PAYLOAD="{\"id\":$ADMIN_ID, \"name\":\"GeoNeo Admin\", \"email\":\"$ADMIN_NEW_EMAIL\", \"password\":\"$ADMIN_NEW_PASS\", \"administrator\":true}"
    curl -s -u "$ADMIN_EMAIL:$ADMIN_OLD_PASS" -X PUT -H "Content-Type: application/json" -d "$UPDATE_ADMIN_PAYLOAD" "$API_URL/users/$ADMIN_ID" > /dev/null
    echo " -> Admin updated. (Email: $ADMIN_NEW_EMAIL, Pass: $ADMIN_NEW_PASS)"
else
    echo " -> Default admin not found or already changed."
fi

echo "2. Creating default mockup user..."
# Check if user already exists
USER_EXISTS=$(curl -s -u "$ADMIN_NEW_EMAIL:$ADMIN_NEW_PASS" -H "Accept: application/json" "$API_URL/users" | grep -o "\"email\":\"$USER_EMAIL\"")

if [ -n "$USER_EXISTS" ]; then
    echo " -> Mockup user already exists."
else
    CREATE_USER_PAYLOAD="{\"name\":\"$USER_NAME\", \"email\":\"$USER_EMAIL\", \"password\":\"$USER_PASS\"}"
    curl -s -u "$ADMIN_NEW_EMAIL:$ADMIN_NEW_PASS" -X POST -H "Content-Type: application/json" -d "$CREATE_USER_PAYLOAD" "$API_URL/users" > /dev/null
    echo " -> Mockup user created. (Email: $USER_EMAIL, Pass: $USER_PASS)"
fi

echo "Initialization complete!"
