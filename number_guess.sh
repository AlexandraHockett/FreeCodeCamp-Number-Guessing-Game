#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read username_input

# Escape single quotes in username
escaped_username=$(echo "$username_input" | sed "s/'/''/g")

# Check if user exists
user_info=$($PSQL "SELECT games_played, best_game FROM users WHERE username='$escaped_username'")

if [[ -z $user_info ]]; then
  # New user
  echo "Welcome, $username_input! It looks like this is your first time here."
  $PSQL "INSERT INTO users(username) VALUES ('$escaped_username')" >/dev/null
else
  # Existing user
  IFS='|' read -r games_played best_game <<< "$user_info"
  echo "Welcome back, $username_input! You have played $games_played games, and your best game took $best_game guesses."
fi

# Generate secret number
secret_number=$(( RANDOM % 1000 + 1 ))
number_of_guesses=0

echo "Guess the secret number between 1 and 1000:"

# Game loop
while true; do
  read guess

  # Check if guess is integer
  if [[ ! "$guess" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  ((number_of_guesses++))

  if (( guess == secret_number )); then
    break
  elif (( guess > secret_number )); then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
done

# Game over, update stats
$PSQL "UPDATE users SET games_played = games_played + 1, best_game = CASE WHEN best_game IS NULL OR $number_of_guesses < best_game THEN $number_of_guesses ELSE best_game END WHERE username = '$escaped_username'" >/dev/null

echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"