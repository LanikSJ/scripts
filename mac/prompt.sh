#!/usr/bin/env bash

# Function to set the terminal title
set_terminal_title() {
  # OSC 0 ; <string> ST  (Set icon name and window title to <string>)
  # \033]0; is the start sequence for setting the window title.
  # \007 is the bell character, which terminates the sequence.
  echo -ne "\033]0;${USER}@${HOSTNAME%%.*}\007"
}

# Add the function to the precmd_functions array, which runs before each prompt.
# This ensures the terminal title is updated before each new prompt is displayed.
typeset -ga precmd_functions
precmd_functions+=(set_terminal_title)
