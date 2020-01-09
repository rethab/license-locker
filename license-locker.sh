#!/bin/bash

set -eu

COMMAND="help"
PACKAGER=""

# we use tsv, because it groups by default and the package names within the
# grouping are not sorted. The line-by-line output is not sorted either, but
# we can fix that easily by piping it through the sort command.
GENERATE_COMMAND_CARGO="cargo-license --tsv | sort"
VERIFY_COMMAND_CARGO="cargo-license"
LICENSE_LOCK_FILE_CARGO="cargo-licenses.lock"
NAME_EXTRACTOR_CARGO="awk 'BEGIN{ORS=\" \"}; {print \$1}'"


# drop the headline with tail
GENERATE_COMMAND_NPM="license-checker --csv --production | tail -n +2"
VERIFY_COMMAND_NPM="license-checker"
LICENSE_LOCK_FILE_NPM="npm-licenses.lock"
NAME_EXTRACTOR_NPM="awk 'BEGIN{ORS=\" \";FS=\",\"}; {print \$1}' | tr -d '\"'"

function show_help(){
  printf 'License Locker (c) Reto Habluetzel\n\n';
  printf 'Generate lock files with all used licenses and run\n';
  printf 'the check in CI to make sure you have an up to date\n';
  printf 'list of used licenses.\n\n';
  printf 'Generate a lock file:\n';
  printf '\t./license-locker.sh --generate\n\n';
  printf 'Check whether the lock file is up to date\n';
  printf '\t./license-locker.sh --check\n\n';
  printf 'Options:\n';
  printf '\t--packager:\tnpm or cargo\n';
  printf '\t--help:\t\tshow this help\n';
}

while [[ "$#" -gt 0 ]]; do case $1 in

  # commands
  --check)    COMMAND="check";;
  --generate) COMMAND="generate";;
  --help)     COMMAND="help";;

  # options
  --packager) PACKAGER="$2"; shift;;

  # general
  *)          printf 'Error: Unknown parameter: %s\n' "$1" >&2; exit 1;;
esac; shift; done

if [ "$COMMAND" = "help" ]
then
  show_help
  exit 0
fi

# try to guess packager
if [ -z "$PACKAGER" ]
then
  if [ -e "Cargo.toml" ]
  then
    PACKAGER="cargo";
  fi

  if [ -e "package.json" ]
  then
    if [ -n "$PACKAGER" ]
    then
      printf 'Error: Cannot determine packager due to amiguity. Please use --packager\n' >&2
      exit 1
    fi
    PACKAGER="npm";
  fi
fi

case $PACKAGER in
  cargo)
    GENERATE_COMMAND=$GENERATE_COMMAND_CARGO
    VERIFY_COMMAND=$VERIFY_COMMAND_CARGO
    LICENSE_LOCK_FILE=$LICENSE_LOCK_FILE_CARGO
    NAME_EXTRACTOR=$NAME_EXTRACTOR_CARGO
    ;;
  npm)
    GENERATE_COMMAND=$GENERATE_COMMAND_NPM
    VERIFY_COMMAND=$VERIFY_COMMAND_NPM
    LICENSE_LOCK_FILE=$LICENSE_LOCK_FILE_NPM
    NAME_EXTRACTOR=$NAME_EXTRACTOR_NPM
    ;;

  *)
    printf 'Errror: Unknown packager: %s\n' "$PACKAGER" >&2
    exit 1
    ;;
esac

if ! [ -x "$(command -v ${VERIFY_COMMAND})" ]
then
    printf 'Error: %s missing\n' $VERIFY_COMMAND >&2;
    exit 1;
fi

function generate(){
    eval "$GENERATE_COMMAND" > $LICENSE_LOCK_FILE
    printf "License lock file generated: %s. Commit it to version control.\n" $LICENSE_LOCK_FILE
}

function check(){
    if [ ! -e $LICENSE_LOCK_FILE ]
    then
       printf 'Error: missing %s. Use --generate to create a new one.\n' $LICENSE_LOCK_FILE >&2;
       exit 1;
    fi

    local new_file;
    local difference;
    local differ=false;

    new_file=$(mktemp)
    eval "$GENERATE_COMMAND" > "$new_file"

    difference="$(diff --suppress-common-lines $LICENSE_LOCK_FILE "$new_file")" || differ=true;

    rm "$new_file"

    if [ $differ = true ];
    then
      local added;
      local removed;
      added=$(echo "$difference" | awk '/^>/{print substr($0, 3)}' | eval "$NAME_EXTRACTOR")
      removed=$(echo "$difference" | awk '/^</{print substr($0, 3)}' | eval "$NAME_EXTRACTOR")
      printf 'Lock file is not up to date\n' >&2;
      printf '\tAdded: %s\n' "$added" >&2;
      printf '\tRemoved: %s\n' "$removed" >&2;
      exit 1;
    fi;
}

case $COMMAND in
  generate) generate;;
  check)    check;;
esac;