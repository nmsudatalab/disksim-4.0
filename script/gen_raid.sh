#!/usr/bin/env bash

# paths
DISKSPECS="diskspecs"
TEMPLATES="templates"
OUTPUTS="configs"
WORKDIR=".work"

# defaults
DISK_NAME='QUANTUM_TORNADO_validate'
SYNTH_SIZES='exponential, 0.0, 8.0'
PARV_FILE="-"
REQUESTS_N=1000
SEQ_PROB=0.5
READ_PROB=0.5
PROC_N=1
VERBOSE=
MAPREQUESTS=
DISKS_N=3
STRIPE_UNIT=64

# colors
C_BLUE=$'\e[34m'
C_RED=$'\e[31m'
C_YELLOW=$'\e[93m'
C_GREY=$'\e[90m'
C_END=$'\e[0m'

# usage message
USAGE="\
${C_YELLOW}Usage:${C_END}
  $0 [options] jbod|raid{0|1|3|4|5} [<number_of_disks>]
  $0 -h
"

# help message
HELP="\
${C_YELLOW}Arguments:${C_END}
  jbod|raid{0|1|3|4|5}  raid type
  <number_of_disks>     integer number of disks  (by default ${DISKS_N})

${C_YELLOW}Options:${C_END}
  -h                    show this help screen and exit
  -v                    increase output verbosity
  -m                    print mapping requests
  -o FILE               output parv filename; - for stdout         (by default ${PARV_FILE})
  -r INT                number of I/O requests to generate         (by default ${REQUESTS_N})
  -S FLOAT              probability of sequential access <0.0,1.0> (by default ${SEQ_PROB})
  -R FLOAT              probability of read access       <0.0,1.0> (by default ${READ_PROB})
  -p INT                number of processes to genereate load      (by default ${PROC_N})
  -u INT                stripe unit                                (by default ${STRIPE_UNIT})
  -s REQUEST_SIZE       disksim style request size,
                          default: '${SYNTH_SIZES}'

                        types of sizes:
                          uniform - requiring two floats - minimum and maximum
                            e.g. -s 'uniform, 1.0, 8.0'

                          normal - requiring two floats - mean and variance values
                                 - (stredni hodnota a hodnota rozptylu)
                                 - second value must be nonnegative
                            e.g. -s 'normal, 5.0, 4,0'

                          exponential - requiring two floats - base and mean values
                            e.g. -s 'exponential, 0.0, 16.0'

  -d DISK_NAME          disksim disk to simulate  (by default ${DISK_NAME})
                          available rotational disks:
$(sed -n 's/^ *disksim_disk \+\([^ ]\+\).*/                            \1/p' "${DISKSPECS}"/*.diskspecs | sort)
                          available mem disks:
$(sed -n 's/^ *memsmodel_mems \+\([^ ]\+\).*/                            \1/p' "${DISKSPECS}"/*.diskspecs | sort)
                          available ssd disks:
$(sed -n 's/^ *ssdmodel_ssd \+\([^ ]\+\).*/                            \1/p' "${DISKSPECS}"/*.diskspecs | sort)
"

### subs

# print verbose message
verbose () {
  ((VERBOSE)) && printf "${C_GREY}${0}${C_END}${C_BLUE}[debug]${C_END}: %s\n" "$@" >&2
}

# print fatal message and exit
fatal () {
  printf "${C_GREY}${0}${C_END}${C_RED}[error]${C_END}: %s\n" "$1" "${USAGE}" >&2
  exit 1
}

# print usage and exit
print_usage () {
  printf -- "%s\n" "${USAGE}" >&2
  exit 0
}

# print help screen and exit
print_help () {
  printf -- "%s\n" "${USAGE}" "${HELP}" >&2
  exit 0
}

# print template file with shell evaluation
template () {
  verbose "parse template: $1"
  eval "echo \"$(sed 's/"/\\"/g' "$1")\""
}

### main

# get options
while getopts ':hvmo:r:S:R:p:u:s:d:' opt; do
  case "${opt}" in
     h) print_help;;
     v) VERBOSE=1;;
     m) MAPREQUESTS=1;;
     o) PARV_FILE="${OPTARG}";;
     r) REQUESTS_N="${OPTARG}";;
     S) SEQ_PROB="${OPTARG}";;
     R) READ_PROB="${OPTARG}";;
     p) PROC_N="${OPTARG}";;
     u) STRIPE_UNIT="${OPTARG}";;
     s) SYNTH_SIZES="${OPTARG}";;
     d) DISK_NAME="${OPTARG}";;
    \?) verbose "${USAGE}"; exit 2;;
  esac
done
shift "$((OPTIND - 1))"

# get arguments
[ -n "$1" ] && RAID_TYPE="$1" || print_usage
[ -n "$2" ] && DISKS_N="$2"

# check arguments and options
[[ "${RAID_TYPE}" =~ ^(raid(0|1|3|4|5)|jbod)$       ]] || fatal "Unsupported raid type (${RAID_TYPE})"
[[ "${DISKS_N}"   =~ ^[1-9][0-9]*$                  ]] || fatal "Invalid number of disks (${DISKS_N})"
[[ "${REQUESTS_N}" =~ ^[[:digit:]]+$                ]] || fatal "Invalid number of requests (${REQUESTS_N})"
(( REQUESTS_N >= 1                                  )) || fatal "Invalid number of requests: should be >=1 (is ${REQUESTS_N})"
[[ "${SEQ_PROB}" =~ ^([[:digit:]]+.)?[[:digit:]]+$  ]] || fatal "Invalid seq probability format (${SEQ_PROB})"
[[ "$(bc<<<"${SEQ_PROB}<=1")" == '1'                ]] || fatal "Invalid seq probability: should be <=1.0 (${SEQ_PROB})"
[[ "${READ_PROB}" =~ ^([[:digit:]]+.)?[[:digit:]]+$ ]] || fatal "Invalid read probability format (${READ_PROB})"
[[ "$(bc<<<"${READ_PROB}<=1")" == '1'               ]] || fatal "Invalid read probability: should be <=1.0 (${READ_PROB})"
[[ "${PROC_N}" =~ ^[[:digit:]]+$                    ]] || fatal "Invalid number of processes (${PROC_N})"
(( PROC_N >= 1                                      )) || fatal "Invalid number of processes: should be >=1 (is ${PROC_N})"
[[ "${STRIPE_UNIT}" =~ ^[[:digit:]]+$               ]] || fatal "Invalid stripe unit (${STRIPE_UNIT})"
(( STRIPE_UNIT >= 1                                 )) || fatal "Invalid stripe unit: should be >=1 (is ${STRIPE_UNIT})"
[[ -n "${PARV_FILE}"                                ]] || fatal "Invalid output parv file: empty"
[[ -n "${SYNTH_SIZES}"                              ]] || fatal "Invalid disksim style request size: empty"
[[ -n "${DISK_NAME}"                                ]] || fatal "Invalid disksim disk to simulate: empty"

# check minimal disks requirement
case "${RAID_TYPE}" in
  raid0|raid1)
    (( DISKS_N < 2 )) && fatal "Unsufficient number of disks: ${RAID_TYPE} requires at least 2 disks (requested ${DISKS_N})";;
  raid3|raid4|raid5)
    (( DISKS_N < 3 )) && fatal "Unsufficient number of disks: ${RAID_TYPE} requires at least 3 disks (requested ${DISKS_N})";;
esac

# map requests?
if (( MAPREQUESTS )); then
  PRINT_MAPREQUESTS='Print maprequests = 1,'
  SYNTH_TMPL=synthgen_linear.tmpl
else
  PRINT_MAPREQUESTS=
  SYNTH_TMPL=synthgen.tmpl
fi

# get disk type
DISK_TYPE="$(sed -n "s/^ *\(disksim_disk\|memsmodel_mems\|ssdmodel_ssd\) \+${DISK_NAME} .*/\1/p" "${DISKSPECS}"/*.diskspecs 2>/dev/null)"
[ -n "${DISK_TYPE}" ] || fatal "Cannot get disk type for disk name ${DISK_NAME}"

# get diskspecs file
DISK_SPEC="$(cd "${DISKSPECS}" && grep -El "(disksim_disk|memsmodel_mems|ssdmodel_ssd) +${DISK_NAME} " ./*.diskspecs 2>/dev/null)"
[ -n "${DISK_SPEC}" ] || fatal "Cannot get diskspecs file name for disk name ${DISK_NAME}"

# create list of devices
DEVICES=
for (( i=0; i<DISKS_N; i++ )); do
  DEVICES="${DEVICES}${DEVICES:+, }disk$i"
done

# create list of disk topology
DISKS_TOPOLOGY=
for (( i=0; i<DISKS_N; i++ )); do
  DISKS_TOPOLOGY="${DISKS_TOPOLOGY}${DISKS_TOPOLOGY:+, }${DISK_TYPE} disk$i []"
done

# verbose?
if (( VERBOSE )); then
  PRINT_STATS=1
  for v in RAID_TYPE DISKS_N DISK_NAME DISK_TYPE DISK_SPEC DEVICES DISKS_TOPOLOGY SYNTH_SIZES STRIPE_UNIT SEQ_PROB READ_PROB REQUESTS_N PROC_N PRINT_STATS PRINT_MAPREQUESTS; do
    eval "verbose \"variable $v: '\${$v}'\""
  done
else
  PRINT_STATS=0
fi

# template logorg block and a single generator
LOGORG_BLOCK="$(template "${TEMPLATES}/logorg_${RAID_TYPE}.tmpl")"
GENERATOR="$(template "${TEMPLATES}/${SYNTH_TMPL}")"

# create list of generators
GENERATORS=
for (( i=0; i<PROC_N; i++ )); do
  GENERATORS="${GENERATORS}${GENERATORS:+,
}${GENERATOR}"
done

# create folders
mkdir -p "${WORKDIR}" "${OUTPUTS}"

# generate template
if [ "${PARV_FILE}" = '-' ]; then
  template "${TEMPLATES}/main.tmpl"
else
  template "${TEMPLATES}/main.tmpl" >"${PARV_FILE}"
  verbose "generated param file: ${PARV_FILE}"
fi
