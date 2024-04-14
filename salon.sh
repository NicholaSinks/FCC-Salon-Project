#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=salon --tuples-only --no-align -c"

if [[ "$1" == "truncate" ]]
then
  echo "$($PSQL "TRUNCATE TABLE customers, appointments")"
  echo "$($PSQL "SELECT setval(pg_get_serial_sequence('customers', 'customer_id'), coalesce(MAX(customer_id), 1)) from customers")"
  echo "$($PSQL "SELECT setval(pg_get_serial_sequence('appointments', 'appointment_id'), coalesce(MAX(appointment_id), 1)) from appointments")"
fi

MENU () {
#  if [[ -n $1 ]]
#  then
#    echo -e "\n$1"
#  else
#    echo -e "\nPlease request a service below"
#  fi
  echo $($PSQL "SELECT * FROM  services") | echo -e "$(sed -E 's/ /\n/g')" | while IFS="|" read -e NUMBER SERVICE
  do
    echo "$NUMBER) $SERVICE"
  done

  read SERVICE_ID_SELECTED
  SELECTION=$SERVICE_ID_SELECTED
  SELECTION_TESTED_ISNUM=$(echo $SELECTION | sed -E 's/[0-9]//')
  OPTIONS=$($PSQL "SELECT service_id FROM services")
  SELECTION_TESTED_ISOPTION=$(echo $OPTIONS | sed -E "s/.*($SELECTION).*/\1/")
  if [[ -n $SELECTION_TESTED_ISNUM ]]
  then
    MENU "Please enter a valid one digit number."
  else
    if [[ "$SELECTION" != "$SELECTION_TESTED_ISOPTION" ]]
    then
      MENU "Please enter a valid option from the list."
    else
      SELECTION_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SELECTION")
    echo -e "\nWhat is your phone number?"
    read CUSTOMER_PHONE
    PHONE=$CUSTOMER_PHONE
    NAME=$($PSQL "SELECT name FROM customers WHERE phone='$PHONE'")
    if [[ -z $NAME ]]
    then
      echo -e "\nWe don't have that number on record. Please tell me your name"
      read CUSTOMER_NAME
      NAME=$CUSTOMER_NAME
      INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$NAME', '$PHONE')")
      echo -e "\nI have added you to our customers list, $NAME."
    fi
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$PHONE'")
    NAME=$($PSQL "SELECT name FROM customers WHERE customer_id=$CUSTOMER_ID")
    echo -e "\nWhat time do you want your $SELECTION_NAME, $NAME?"
    read SERVICE_TIME
    TIME=$SERVICE_TIME
    INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SELECTION, '$TIME')")
    echo "I have put you down for a $SELECTION_NAME at $TIME, $NAME."
    fi
  fi
}

MENU
