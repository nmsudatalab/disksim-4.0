#!/usr/bin/perl -w

# grep interresting lines
while (defined ($_=<>)) {
  if (m!^Overall I/O System (.*?):\s*(.*)!) {
    printf("%s:%s%s\n", $1, " "x(42-length($1)), $2);
  }
}
