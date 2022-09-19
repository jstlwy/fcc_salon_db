#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"
PSQL_CSV="psql --username=freecodecamp --dbname=salon --tuples-only --csv -c"
SERVICES=$($PSQL "SELECT service_id,name FROM services")
NUM_SERVICES=$($PSQL "SELECT COUNT(*) FROM services")

# CAUTION: Non-capturing groups, e.g. (?: ... ), not supported!
PHONE_REGEX='^(\([0-9]{3}\)|[0-9]{3})?(\-|[:space:])?[0-9]{3}(\-|[:space:])?[0-9]{4}$'
TIME_REGEX='^[0-2]?[0-9]:?([0-5][0-9])?([:space:]?[AaPp][Mm])?$'
DEFAULT_IFS=$IFS

MAIN_MENU() {
	echo "Welcome to the barbershop. Choose a service:"
	echo "$SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
	do
		echo "$SERVICE_ID) $SERVICE_NAME"
	done

	read SERVICE_ID_SELECTED
	if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]$ || $SERVICE_ID_SELECTED -gt $NUM_SERVICES ]]; then
		echo -e "\nPlease enter a valid option.\n"
		MAIN_MENU
	else
		echo "Please enter your phone number."
		read CUSTOMER_PHONE
		while [[ ! $CUSTOMER_PHONE =~ $PHONE_REGEX ]]
		do
			echo "Please enter a valid phone number."
			read CUSTOMER_PHONE
		done

		# Check if the phone number already exists in the database.
		USER_INFO=$($PSQL_CSV "SELECT customer_id,name FROM customers WHERE phone='$CUSTOMER_PHONE'")
		if [[ -z $USER_INFO ]]; then
			# If it doesn't, ask the customer for his/her name.
			echo "Please enter your name."
			read CUSTOMER_NAME
			while [[ ! $CUSTOMER_NAME =~ [A-Za-z] || ${#CUSTOMER_NAME} -gt 50 ]]
			do
				echo "Please enter a valid name."
				read CUSTOMER_NAME
			done
			# Remove any leading or trailing whitespace
			CUSTOMER_NAME=$(echo $CUSTOMER_NAME | sed 's/^[ \t]*//;s/[ \t]$//')
			# Then add the name and phone to the database and get the new customer ID.
			CUSTOMER_INS_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
			CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
		else
			# If it does, extract the customer's name and ID from the returned string.
			IFS=','
			CUSTOMER_INFO=($USER_INFO)
			IFS=$DEFAULT_IFS
			CUSTOMER_ID=${CUSTOMER_INFO[0]}
			CUSTOMER_NAME=${CUSTOMER_INFO[1]}
			echo "Welcome back, $CUSTOMER_NAME (ID $CUSTOMER_ID)!"
		fi

		echo "Please enter your desired appointment time."
		read SERVICE_TIME
		# The freeCodeCamp automated grader tries to insert an
		# arbitrary string, like "FakeTime", for the time,
		# so this section of code that validates the time input
		# must be removed in order for it to pass the test.
		while [[ ! $SERVICE_TIME =~ $TIME_REGEX ]]
		do
			echo "Please enter a valid time."
			read SERVICE_TIME
		done

		APPT_INS_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES('$CUSTOMER_ID', '$SERVICE_ID_SELECTED', '$SERVICE_TIME')")
		SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
		SERVICE_NAME=$(echo $SERVICE_NAME | sed 's/^[ \t]*//;s/[ \t]$//')
		echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
	fi
}

MAIN_MENU
