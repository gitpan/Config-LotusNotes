@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!perl
#line 15
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
my @all_confs = $conf->all_configurations();
my $default   = eval { $conf->default_configuration() };

print "Lotus Notes installs on node ", Win32::NodeName(), ":\n";
print "-" x (length(Win32::NodeName())+30), "\n";

if (@all_confs) {
    printf "%-8s %-7s %s\n", 'version', 'type', 'path';
    foreach my $conf (sort by_version_and_type @all_confs) {
        printf "%-8s %-7s %s %s\n", 
            $conf->version, 
            $conf->is_server ? 'server' : 'client', 
            $conf->notespath,
            ($default and $conf->notespath eq $default->notespath) 
                ? '(default)'
                : ''
                ,
            ;
    }
}
else {
    print "none\n";
}


sub by_version_and_type {
       $a->version   cmp $b->version
    || $a->is_server <=> $b->is_server
}

__END__
:endofperl
