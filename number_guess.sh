#!/bin/bash

# Set up PSQL command for database queries
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt user for their username
echo "Enter your username:"
read username_input

# Escape single quotes in the username to prevent SQL injection
escaped_username=$(echo "$username_input" | sed "s/'/''/g")

# Check if user exists in the database
user_info=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$escaped_username'")

if [[ -z $user_info ]]; then
  # New user message and insert into database
  echo "Welcome, $username_input! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES ('$escaped_username')" >/dev/null
else
  # Existing user message with stats
  IFS='|' read -r games_played best_game <<< "$user_info"
  echo "Welcome back, $username_input! You have played $games_played games, and your best game took $best_game guesses."
fi

# Generate a random number for the guessing game
secret_number=$(( RANDOM % 1000 + 1 ))
number_of_guesses=0

echo "Guess the secret number between 1 and 1000:"

# Start of game loop
while true; do
  read guess

  # Check if input is a valid integer
  if [[ ! "$guess" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((number_of_guesses++))

  # Compare guess with secret number
  if (( guess == secret_number )); then
    break
  elif (( guess > secret_number )); then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

# Update user stats after guessing the number
$PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $number_of_guesses < best_game THEN $number_of_guesses ELSE best_game END WHERE username = '$escaped_username'" >/dev/null

# Display result message
echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"