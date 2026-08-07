#!/usr/bin/env bash

# Array of customers: "id|first_name|last_name|email"
customers=(
  "01|Jill|Smith|jsmith%40cloudNativeData.io"
  "02|John|Doe|jdoe%40cloudNativeData.io"
  "03|Alice|Johnson|ajohnson%40cloudNativeData.io"
  "04|Bob|Williams|bwilliams%40cloudNativeData.io"
  "05|Charlie|Brown|cbrown%40cloudNativeData.io"
  "06|Diana|Prince|dprince%40cloudNativeData.io"
  "07|Evan|Wright|ewright%40cloudNativeData.io"
  "08|Fiona|Gallagher|fgallagher%40cloudNativeData.io"
)


  for customer in "${customers[@]}"; do
    IFS='|' read -r id first_name last_name email <<< "$customer"

    echo "Submitting customer ID: $id ($first_name $last_name)..."

    curl -X 'POST' \
      "http://localhost:8070/customers?id=${id}&first_name=${first_name}&last_name=${last_name}&email=${email}" \
      -H 'accept: */*' \
      -d ''

    echo -e "\n---"
    sleep 1
  done


# Infinite loop (Press Ctrl+C to stop)
while true; do
  echo "=== Starting customer submission batch ==="

  for customer in "${customers[@]}"; do
    IFS='|' read -r id first_name last_name email <<< "$customer"

    echo "Submitting customer ID: $id ($first_name $last_name)..."


    curl -X 'GET' \
    "http://localhost:8070/customers/${id}" \
    -H 'accept: */*'


    echo -e "\n---"
    sleep 1
  done

  echo " finished. Pausing for 5 seconds..."
  sleep 5
done



