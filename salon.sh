#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"
SERVICES=$($PSQL "SELECT * FROM services")
NUM_SERVICES=$($PSQL "SELECT COUNT(*) FROM services")
echo $NUM_SERVICES

MAIN_MENU() {
  echo "Welcome to the barbershop. Choose a service:"
  echo "$SERVICES" | while read SERVICE_NO BAR SERVICE
  do
    echo "$SERVICE_NO) $SERVICE"
  done

  read SERVICE_CHOICE
  if [[ ! $SERVICE_CHOICE =~ ^[0-9]+$ || $SERVICE_CHOICE -gt $NUM_SERVICES ]]; then
    echo -e "\nPlease enter a valid option.\n"
    MAIN_MENU
  else
    echo "Hello"
  fi
}

MAIN_MENU

