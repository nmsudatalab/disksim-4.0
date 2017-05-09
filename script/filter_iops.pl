#!/usr/bin/perl -w

# format
my $format = "%-25s %12.5f\n";

# grab interresting lines
while (defined ($_=<>)) {
  if      (m!^Overall I/O System Response time average:\s*([\d\.]+)!) {
    $lat = $1;
  } elsif (m!^Overall I/O System Requests per second:\s*([\d\.]+)!) {
    $io_rps = $1;
  } elsif (m!^Disk #0 Requests per second:\s*([\d\.]+)!) {
    $d0_rps = $1;
  } elsif (m!^Overall I/O System Request size average:\s*([\d\.]+)!) {
    $io_size = $1;
  } elsif (m!^Disk #0 Request size average:\s*([\d\.]+)!) {
    $d0_size = $1;
  }
}

# print results
printf $format, "Average latency  [ms]:", $lat;
printf $format, "RAID   I/O per second:", $io_rps;
printf $format, "RAID    kB per second:", $io_size * $io_rps / 2;
printf $format, "DISK#0 I/O per second:", $d0_rps;
printf $format, "DISK#0  kB per second:", $d0_size * $d0_rps / 2;
