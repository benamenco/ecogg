#
# (c) Giorgio Gonnella, ZBH
#
# %-PURPOSE-%
# General support functions for bash scripts
#

function function_exists {
  declare -F $1 > /dev/null
  return $?
}
export -f function_exists

function die { local msg=$1
  if function_exists usage; then
    usage > /dev/stderr
  fi
  if [ "$msg" != "" ]; then
    echo -e "\nError: $msg\n" > /dev/stderr
  fi
  # Calling from interactive shell does not exit the shell
  # but sets $? to 1.
  if [ ! -v PS1 ]; then
    exit 1
  else
    false
  fi
}
export -f die

function require_program { local progname=$1
  if ! (which $progname > /dev/null 2> /dev/null); then
    die "$progname not found in path"
  else
    true
  fi
}
export -f require_program

function require_file { local file=$1
  if [ ! -e "$file" ]; then
    die "file not found ($file)"
  else
    true
  fi
}
export -f require_file

function require_var { local var=$1 to=$2
  if [ "$to" != "" ]; then
    msg="Set the variable $var to the $to"
  else
    msg="Variable shall not be empty ($var)"
  fi
  var_value=$(eval echo \$$var)
  if [ "$var_value" == "" ]; then
    die "$msg"
  else
    true
  fi
}
export -f require_var

function check_n_args { local expargs=$1 nargs=$2
  if [ $nargs -ne $expargs ]; then
    die "$expargs arguments required, $nargs found"
  else
    true
  fi
}
export -f check_n_args

function check_arg_list {
  local to_check=$1
  shift
  valid=false
  for value in $*; do
    if [ "$to_check" == "$value" ]; then
      valid=true
      break
    fi
  done
  if ! $valid; then
    die "$to_check is not one of: $*"
  else
    true
  fi
}
export -f check_arg_list

