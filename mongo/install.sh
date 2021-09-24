#!/bin/zsh
# Must be run with zsh to complete the MVM_PATHS substitution.

# Install m, a mongo version manager.
# https://github.com/aheckmann/m
MVM=$HOME/.mongo-version-manager

# If m has already been installed, remove so we can refresh it.
if [[ -d $MVM ]]; then
  rm -rf $MVM
fi

# Ensure the required versioning directory exists
export MVM_PATHS='/usr/local/m/versions:/usr/local/bin/m:/usr/local/m/tools/versions'
for mvm_path in ${(s/:/)MVM_PATHS}; do
  echo $mvm_path
  if [[ ! -d $mvm_path ]]; then
    echo 'You must enter your password to create the necessary directories for mongo version manager!'
    sudo mkdir -p $mvm_path
  fi
done

git clone git://github.com/aheckmann/m.git $MVM && cd $MVM && sudo make install
