alias k='kubectl'

kubectx() {
  ################
  # This is a util to make picking and setting a kubectl context easier.
  # The command should get existing contexts, present an interactive selection to the user,
  # and then make the selection the context
  ################

  # Make sure word splitting works as expected in zsh.
  setopt sh_word_split

  # Get the list of contexts
  contexts="$(kubectl config get-contexts -o name)"

  # Check if there are any contexts available
  if [ -z "$contexts" ]; then
    echo "No kubectl contexts found."
    exit 1
  fi

  # Present the contexts to the user for selection
  echo "Select a kubectl context:"
  select context in $contexts; do
    if [ -n "$context" ]; then
      # Set the selected context
      kubectl config use-context "$context"
      break
    else
      echo "Invalid selection. Please try again."
    fi
  done
}