#!/usr/bin/perl -w

sub pure_length {
  my ($str) = @_;
  $str =~ s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g;
  return length($str);
}

# colors
my @colors = ("\e[32;1m", "\e[31;1m", "\e[33;1m", "\e[34;1m", "\e[35;1m", "\e[36;1m");
my $no_color = "\e[0m";

# grep interresting lines
while (defined ($_=<>)) {
  if (/^logorg_maprequest: logorg ([^,]+), dev ([^,]+), blkno (\d+), opid (\d+)/) {
    $d{$2} = 1;
    $l{$1} = $colors[(scalar keys %l)%(0 + @colors)] unless (exists($l{$1}));
    push @{$h{$3}{$2}}, $l{$1} . $4 . $no_color;
  }
}

# print nothing if nothing was found
exit unless (%h);

# sorted list of devices
@devices = sort keys %d;

# print logorgs:
printf "\nMapping for logorg%s", ((scalar keys %l)>1 ? "s" : "");
for my $logorg (sort keys %l) {
  printf " %s%s%s", $l{$logorg}, $logorg, $no_color;
}
printf ":\n\n";

# print header
printf "%10s  ", "block";
for my $dev (@devices) {
  printf " %-20s", $dev;
}
printf "\n";

# print header line
printf "  "."-"x9;
for my $dev (@devices) {
  printf "+" . "-"x20;
}
printf "\n";

# print blocks as rows
for my $block (sort keys %h) {
  printf "%10d  ", $block;
  for my $dev (@devices) {
    $_ = exists($h{$block}{$dev}) ? join(",", @{$h{$block}{$dev}}) : '';
    printf " %s%s", $_, " "x(20-pure_length($_));
  }
  printf "\n";
}
printf "\n";
