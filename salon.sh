#!/bin/bash

# Define the PSQL command to interact with the PostgreSQL database.
# -X disables reading the ~/.psqlrc file
# --username and --dbname specify the login
# --tuples-only removes headers and footers (just the raw data)
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

# Function to display available services from the database
DISPLAY_SERVICES() {
  # Query all services from the database
  SERVICES=$($PSQL "SELECT service_id, name FROM services")

  # Loop through each service and print it in "ID) Name" format
  echo "$SERVICES" | while read SERVICE_ID BAR SERVICE
  do
    echo "$SERVICE_ID) $SERVICE"
  done
}

# Main function to drive the appointment booking process
MAIN_MENU() {
  # If a message was passed in, display it (used for errors)
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # Display the list of services
  DISPLAY_SERVICES

  # Prompt the user to select a service by entering its ID
  read SERVICE_ID_SELECTED

  # Get the name of the selected service from the database
  SERVICE=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")

  # If no service is found (invalid ID), show an error and restart the menu
  if [[ -z $SERVICE ]]
  then
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    # Ask for the customer's phone number
    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE

    # Check if the customer already exists by phone number
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

    # If the customer is not found, prompt for their name and insert into DB
    if [[ -z $CUSTOMER_NAME ]]
    then
      echo -e "\nI don't have a record for that phone number, what's your name?"
      read CUSTOMER_NAME
      $PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')"
    fi

    # Ask the customer what time they want the appointment
    # Use sed to trim any whitespace from the service name
    echo -e "\nWhat time would you like your $(echo $SERVICE | sed -E 's/^ *| *$//g'), $CUSTOMER_NAME?"
    read SERVICE_TIME

    # Retrieve the customer's ID using their phone number
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

    # Insert the appointment into the appointments table
    $PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')"

    # Confirm the booking to the user
    echo -e "\nI have put you down for a $(echo $SERVICE | sed -E 's/^ *| *$//g') at $SERVICE_TIME, $CUSTOMER_NAME."
  fi
}

# Initial welcome message when the script runs
echo -e "\n~~~~~ MY SALON ~~~~~\n"
echo -e "Welcome to My Salon, how can I help you?\n"

# Start the main menu
MAIN_MENU
