# This script produces a table with information on all Lotus Notes
# installs found on the local computer.
# If run with a -d commandline parameter, it also produces diagnostic output.

use strict;
use warnings;
use lib "../lib";
use Config::LotusNotes;

my %options;
$options{debug} = 1 if $ARGV[0]||'' eq '-d';

my $conf = Config::LotusNotes->new(%options);
my $default   = $conf->default_configuration()
    or die "No Lotus Notes installs found";
my @all_confs = $conf->all_configurations();

print "Lotus Notes installs on ", Win32::NodeName(), ":\n";
print "-" x (length(Win32::NodeName())+25), "\n";

printf "%-8s %-7s %s\n", 'version', 'type', 'path';
foreach my $conf (sort by_version_and_type @all_confs) {
    printf "%-8s %-7s %s %s\n", 
        $conf->version, 
        $conf->is_server ? 'server' : 'client', 
        $conf->notespath,
        $conf->notespath eq $default->notespath ? '(default)' : '',
        ;
}


sub by_version_and_type {
       $a->version   cmp $b->version
    || $a->is_server <=> $b->is_server
}
