#!/usr/bin/env bash
# Collect and represent disksim metrics

# settings
WORKDIR=.work

# help?
if [ -z "$1" -o "$1" = '-h' ]; then
  cat <<__END_OF_HELP__
Collect and represent disksim metrics

Usage for collecting metrics:
  $0 -p <max_num_of_processes> [gen_raid_options] jbod|raid{0|1|3|4|5} [<number_of_disks>]

Usage for get ASCII metrics:
  $0 --ascii <metric> ...

Usage for get gnuplot metrics:
  $0 ---gnuplot <metric> ...

Availaible metrics:
  'Average # requests'
  'Average queue length'
  'Avg # read requests'
  'Avg # write requests'
  'Base SPTF/SDF Different'
  'Batch size average'
  'Batch size maximum'
  'Batch size std.dev.'
  'Completely idle time'
  'Critical Read Response time average'
  'Critical Read Response time maximum'
  'Critical Read Response time std.dev.'
  'Critical Reads'
  'Critical Write Response time average'
  'Critical Write Response time maximum'
  'Critical Write Response time std.dev.'
  'Critical Writes'
  'End # requests'
  'End queued requests'
  'Idle period length average'
  'Idle period length maximum'
  'Idle period length std.dev.'
  'Instantaneous queue length average'
  'Instantaneous queue length maximum'
  'Instantaneous queue length std.dev.'
  'Inter-arrival time average'
  'Inter-arrival time maximum'
  'Inter-arrival time std.dev.'
  'Max # read requests'
  'Max # write requests'
  'Maximum # requests'
  'Maximum queue length'
  'Non-Critical Read Response time average'
  'Non-Critical Read Response time maximum'
  'Non-Critical Read Response time std.dev.'
  'Non-Critical Reads'
  'Non-Critical Write Response time average'
  'Non-Critical Write Response time maximum'
  'Non-Critical Write Response time std.dev.'
  'Non-Critical Writes'
  'Number of batches'
  'Number of idle periods'
  'Number of reads'
  'Number of writes'
  'Overlaps combined'
  'Physical access time average'
  'Physical access time maximum'
  'Physical access time std.dev.'
  'Priority SPTF/SDF Different'
  'Queue time average'
  'Queue time maximum'
  'Queue time std.dev.'
  'Read inter-arrival average'
  'Read inter-arrival maximum'
  'Read inter-arrival std.dev.'
  'Read overlaps combined'
  'Read request size average'
  'Read request size maximum'
  'Read request size std.dev.'
  'Request size average'
  'Request size maximum'
  'Request size std.dev.'
  'Requests per second'
  'Response time average'
  'Response time maximum'
  'Response time std.dev.'
  'runlistlen'
  'runoutstanding'
  'Sequential reads'
  'Sequential writes'
  'setsize'
  'simtime'
  'Sub-optimal mapping penalty average'
  'Sub-optimal mapping penalty maximum'
  'Sub-optimal mapping penalty std.dev.'
  'Timeout SPTF/SDF Different'
  'Total Requests handled'
  'warmuptime'
  'Write inter-arrival average'
  'Write inter-arrival maximum'
  'Write inter-arrival std.dev.'
  'Write request size average'
  'Write request size maximum'
  'Write request size std.dev.'
__END_OF_HELP__
  exit 1
fi

# print template file with shell evaluation
template () {
  eval "echo \"$(sed 's/"/\\"/g' "$1")\""
}

print_metric_ascii () {
  local f i
  for f in "${WORKDIR}"/metrics_*.out; do
    i="${f%.*}"; i="${i##*_}";
    sed -n "s!^${1}:\s*\(.*$\)!$i threads: \1!p" "$f"
  done
}

print_metric_gnuplot () {
  local f i
  local METRIC="$1"
  local DESC="$(<"${FILE_DESC}")"

  template "${TEMPLATES}/gnuplot.tmpl" >"${FILE_PLOT}"

  for f in "${WORKDIR}"/metrics_*.out; do
    i="${f%.*}"; i="${i##*_}";
    sed -n "s!^${1}:\s*\(.*$\)!$i \1!p" "$f"
  done | gnuplot -p "${FILE_PLOT}"
}

# templates
TEMPLATES="templates"

# workdir with disksim outputs
FILE_DESC="${WORKDIR}"/metrics.desc
FILE_PLOT="${WORKDIR}"/metrics.plot

# print ascii metrics?
if [ "$1" = '--ascii' ]; then

  shift
  while [ -n "$1" ]; do
    print_metric_ascii "$1"
    shift
  done

# print gnuplot metrics?
elif [ "$1" = '--gnuplot' ]; then

  shift
  while [ -n "$1" ]; do
    print_metric_gnuplot "$1"
    shift
  done

# collect metrics?
else

  # get proc count
  PROC_N=
  ARGS=()
  while [ -n "$1" ]; do
    case "$1" in
      '-p')
        shift
        PROC_N="$1"
        ;;
      '-p'*)
        PROC_N="${1#-p}"
        ;;
      *)
        ARGS+=($1)
        ;;
    esac
    shift
  done

  # create description file
  echo "${ARGS[@]}" >"${FILE_DESC}"

  # collect metrics
  rm -f "${WORKDIR}"/metrics_*.out 2>/dev/null
  for i in $(seq 1 "${PROC_N}"); do
    echo -en "\r                                                   \rCollecting metrics for ${i} threads ... "
    printf -v output '%s/metrics_%08d.out' "${WORKDIR}" "$i"
    ./gen_raid.sh -p "$i" "${ARGS[@]}" | ./disksim.sh - | sed -n "s!^Overall I/O System \(.*\)!\1!p" > "${output}"
  done
  echo "done (in ${WORKDIR}/metrics_*.out)"

fi
