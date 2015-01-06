#!/usr/bin/env bash

shopt -s extglob
set -o errtrace
#set -o errexit
set +o noclobber

export NOOP=

ASSUMEYES=0
VERBOSE=0

VM=$PACKER_BUILD_NAME

function usage() # {{{2
{
  echo "$(basename $0) [options]"
} # 2}}}

function parse_args() # {{{2
{
  while :; do
    trace "Analyzing option \"$1\""
    case $1 in
      --vm)
        [[ -z $2 || ${2:0:1} == '-' ]] && die "Argument for option $1 is missing"
        VM=$2
        shift 2
        continue
      ;;
      --vm=*?)
        VM=${1#*=} # delete everything up to =
      ;;
      --vm=)
        die "Argument for option $1 is missing"
        ;;
      --noop|--dry-run)
        warn "This program will execute in dry mode, your system will not be modified"
        NOOP=:
	;;
      -h|-\?|--help)
       trace "Showing usage"
       usage
       exit 1
       ;;
     -v|--verbose)
       VERBOSE=$((VERBOSE + 1))
       trace "Verbose level: $VERBOSE"
       ;;
     -y|--yes|--assumeyes|--assume-yes) # All questions will get a "yes"  answer automatically
       ASSUMEYES=1
       trace "All prompts will be answered \"yes\" automatically"
       ;;
     -?*) # Invalid options
       warn "Unknown option $1 will be ignored"
       ;;
     --) # Force end of options
       shift
       break
       ;;
     *)  # End of options
       break
       ;;
    esac
    shift
  done
} # 2}}}


storage_controller='IDE Controller'
storage_port=1
storage_device=0

function main() # {{{
{
  parse_args "$@"

  VBoxManage storageattach $VM --storagectl "$storage_controller" --port $storage_port --device $storage_device --type dvddrive --medium "emptydrive"
}
main "$@"
# }}}

