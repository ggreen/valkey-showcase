#!/usr/bin/env bash

  for i in $(seq -w 01 16); do
     echo "Posting customer $i..."

     curl -X 'POST' \
       'http://localhost:8070/customers' \
       -H 'accept: */*' \
       -H 'Content-Type: application/json' \
       -d "{
       \"id\": \"$i\",
       \"first_name\": \"Jill$i\",
       \"last_name\": \"Smith\",
       \"email\": \"jsmith$i@cloudNativeData.io\"
     }"

     echo "" # Adds a line break after response output
#     sleep 1
   done


# Infinite loop (Press Ctrl+C to stop)
while true; do
  echo "=== Starting customer submission batch ==="

for i in $(seq -w 01 16); do
     echo "Getting customer $i..."

         curl -X 'GET' \
         "http://localhost:8070/customers/${i}" \
         -H 'accept: */*'

     echo "" # Adds a line break after response output
#     sleep 1
   done


  echo " finished. Pausing for 5 seconds..."
  sleep 5
done



