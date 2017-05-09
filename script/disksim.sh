#!/usr/bin/env bash
# Run DiskSim:
#   * with simplified inputs
#   * fired in the folder with diskpecs files
#   * with colored messages
#   * with printed results

# paths
DISKSPECS="diskspecs"

# colors
color_ok=$'\e[32;01m'
color_title=$'\e[33;01m'
color_err=$'\e[31;01m'
color_note=$'\e[30;01m'
color_file=$'\e[35;01m'
color_none=$'\e[0m'


### subs

# error handling
_err () {
  echo -e "${color_err}Error: $*${color_none}" >&2
  exit 1
}

# get absoluth path of a dir
_abs_dir () {
  (cd "$(dirname "$1")" 2>/dev/null && pwd)
}

# get absoluth path of a file
_abs_file () {
  echo "$(_abs_dir "$1")/${1##*/}"
}


### main

# help?
if [ -z "$1" ]; then
  cat >&2 <<__END_OF_HELP__
${color_file}DiskSim wrapper${color_none}

${color_title}Usage:${color_none}
  $0 [-q] <param_file> [ <output_file> [ <trace_file> [ <trace_type> [ <par_override> ... ] ] ] ]

${color_title}Options:${color_none}
  -q ............... Quiet - supress verbose messages

${color_title}Arguments:${color_none}
  <param_file> ..... Name of the parameter file
                     Set - for standard input

  <output_file> .... Name of the output file
                     Output can be directed to stdout by specifying 'stdout' as a basename,
                       and it quiet verbose messages. That's a default

  <trace_file> ..... Trace file to be used as input
                     Input is taken from stdin when 'stdin' is specified,
                       of course not together with <param_file> from 'stdin'
                     Synthetic workload generation portion of the simulator is enabled
                       instead of a trace file if it is empty, '-' or '0'

  <trace_type> ..... Format of the trace input, like 'ascii', 'validate', 'raw', 'hpl' ...
                     Set to 'ascii' if it's empty, '-' or '0'

  <par_override> ... Replacement for default parameter values or parameter values from <param_file>

${color_title}Notes:${color_none}
  * disksim runs in a folder with diskspecs (${DISKSPECS}/) and temporarily copies <param_file> here
  * it prints colored messages and resulted file list

__END_OF_HELP__
  exit 0
fi

# quiet?
quiet=
if [ "$1" = '-q' ]; then
  quiet=1
  shift
fi

# disksim binary full path
binary="$(_abs_file "$(_abs_dir "${BASH_SOURCE[0]}")/../bin/disksim")"
[ -e "${binary}" ] || _err "Binary ${binary} not found"
[ -f "${binary}" ] || _err "Binary ${binary} is not a file"
[ -x "${binary}" ] || _err "Binary ${binary} is not executable"

# get par_file
par_file="$1"
if [ "${par_file}" != '-' ]; then
  [ -e "${par_file}"    ] || _err "Parameter file ${par_file} not found"
  [ -f "${par_file}"    ] || _err "Parameter file ${par_file} is not a file"
  [ -r "${par_file}"    ] || _err "Parameter file ${par_file} is not readable"
fi
shift

# get out_file and its components
if [ -n "$1" ]; then
  out_file="$1"
  WORKDIR="$(dirname "${out_file}")"
  mkdir -p "${WORKDIR}" || _err "Cannot make dir ${WORKDIR}"
  out_file_abs="$(_abs_file "${out_file}")"
  shift
else
  out_file=stdout
  WORKDIR=.
  out_file_abs="${out_file}"
  quiet=yes
fi

# get trace_file and then synth_gen
trace_file="$1"
if [ -z "${trace_file}" -o "${trace_file}" = - -o "${trace_file}" = 0 ]; then
  trace_file=0
  trace_file_abs=0
  synth_gen=1
elif [ "${trace_file}" = stdin ]; then
  trace_file_abs="${trace_file}"
  synth_gen=0
else
  trace_file_abs="$(_abs_file "${trace_file}")"
  synth_gen=0
fi
shift

# get trace_type
trace_type="$1"
if [ -z "${trace_type}" -o "${trace_type}" = - -o "${trace_type}" = 0 ]; then
  trace_type=ascii
fi
shift

# run disksim
[ -z "${quiet}" ] && echo "${color_title}Run: ${color_file}${binary##*/} ${par_file} ${out_file} ${trace_type} ${trace_file} ${synth_gen}${color_title} $*${color_err}" >&2
t="${DISKSPECS}/.tmp.$$.parv"
if [ "${par_file}" != '-' ]; then
  cp "${par_file}" "$t" || _err "Cannot copy ${par_file} to $t"
else
  cat >"$t"             || _err "Cannot create $t"
fi
(
  cd "${DISKSPECS}"   || _err "Cannot change dir to ${DISKSPECS}"
  "${binary}" "${t##*/}" "${out_file_abs}" "${trace_type}" "${trace_file_abs}" "${synth_gen}" "$@"
)
retcode=$?

# clean-up
rm -f "$t"

# print results
if [ -z "${quiet}" ]; then
  if [ "${retcode}" = 0 ]; then
    if [ "${out_file}" = stdout ]; then
      echo "${color_ok}OK${color_none}"
    else
      echo "${color_ok}OK${color_none} - the result:"
      ls -lh "${out_file}"
      echo
    fi
  else
    echo "${color_err}FAILED${color_note} (with return code ${retcode})${color_none}"
  fi >&2
fi

# exit with same return code as disksim
exit "${retcode}"
