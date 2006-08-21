package Config::LotusNotes;
use strict;
#use warnings;
use Carp;
use Win32::TieRegistry Delimiter => '/';
use Config::LotusNotes::Configuration;

our $VERSION = '0.21';

# constructor ----------------------------------------------------------------

sub new {
    my ($classname, %options) = @_;
    return bless {%options}, $classname;
}


# public methods -------------------------------------------------------------

sub default_configuration {
    my ($self) = @_;
    my $path = _normalize_path($self->_get_default_location());
    return Config::LotusNotes::Configuration->new(path => $path);
}


sub all_configurations {
    my ($self) = @_;
    my @configurations;
    foreach my $path ($self->_get_all_locations()) {
        my $config;
        # skip invalid installs.
        print STDERR "-- Verifying $path - "  if $self->{debug};
        if ( eval {$config = Config::LotusNotes::Configuration->new(path => $path)} ) {
            print STDERR "OK\n"  if $self->{debug};
            push @configurations, $config;
        }
        else {
            carp $@ if $@ =~ /^Error parsing /;
            print STDERR "NOK: $@\n"  if $self->{debug};
        }
    }
    print STDERR "-- Returning " . @configurations . " configuration objects\n"  if $self->{debug};
    return @configurations;
}


# private methods ------------------------------------------------------------

sub _get_default_location {
    my ($self) = @_;
    print STDERR "-- Searching default install\n"  if $self->{debug};

    # first try the handler for the Notes class.
    if (my $class_handler = $self->_get_notes_handler()) {
        return $class_handler;
    }

    # if unsuccessful, try default product keys for Notes and Domino.
    foreach my $product qw(Notes Domino) {
        print STDERR "--  Searching default $product product key\n"  if $self->{debug};
        if (my $path = $Registry->{"LMachine/SOFTWARE/Lotus/$product/Path"}) {
            print STDERR "--   Found $path\n"  if $self->{debug};
            return _normalize_path($path);
        }
    }
    croak 'No Lotus Notes/Domino installation found';
}


sub _get_all_locations {
    my ($self) = @_;
    print STDERR "-- Searching for all installs\n"  if $self->{debug};
    my @all_paths = (
        $self->_get_notes_handler(), 
        $self->_get_registered_locations(), 
        $self->_get_shared_libs_locations(), 
        $self->_get_typelib_locations(),
    );
    # remove duplicates
    my (%seen, @result);
    print STDERR "-- Removing duplicates\n"  if $self->{debug};
    foreach my $path (@all_paths) {
        push @result, $path unless $seen{$path}++;
    }
    return @result;
}


sub _get_notes_handler {
    my ($self) = @_;
    # one install is registered for the Notes class.
    print STDERR "--  Searching Notes class handler\n"  if $self->{debug};
    if (my $path = $Registry->{"Classes/Notes/Shell/Open/Command//"}) {
        $path =~ s/"//g;
        $path =~ s/^(\S+).*/$1/;
        $path =~ s/[^\\]+$//;
        print STDERR "--   Found $path\n"  if $self->{debug};
        return _normalize_path($path);
    }
    return;
}


sub _get_registered_locations {
# finds installs in version specific keys under $RegNotesRoot
    my ($self) = @_;
    my @result;
    foreach my $product qw(Notes Domino) {
        print STDERR "--  Searching default $product product key\n"  if $self->{debug};
        my $product_root = $Registry->{"LMachine/SOFTWARE/Lotus/$product/"};
        if (my $path = $product_root->{'Path'}) {
            print STDERR "--   Found $path\n"  if $self->{debug};
            push @result, _normalize_path($path);
        }
        
        # search for version specific keys
        foreach my $key (keys %$product_root) {
            if ($key =~ m|^\d+(\.\d+)?/$|) {
                if ($self->{debug}) {
                    (my $version = $key) =~ s|/$||;
                    print STDERR "--  Searching $product $version product key\n";
                }
                if (my $path = $product_root->{$key . 'Path'}) {
                    print STDERR "--   Found $path\n"  if $self->{debug};
                    push @result, _normalize_path($path);
                }
            }
        }
    }
    return @result;
}


sub _get_shared_libs_locations {
# search for shared dll entries
    my ($self) = @_;
    print STDERR "--  Searching shared dll entries\n"  if $self->{debug};
    my @result;

    my $shared_dlls = $Registry->{'LMachine/SOFTWARE/Microsoft/Windows/CurrentVersion/SharedDLLs/'};
    foreach my $path (keys %$shared_dlls) {
        if ($path =~ /nlsxbe.dll$/i) {
            $path =~ s|^/||;
            $path =~ s/[^\\]*$//;  # remove program
            print STDERR "--   Found $path\n"  if $self->{debug};
            push @result, _normalize_path($path);
        }
    }
    return @result;
}


sub _get_typelib_locations {
# search the Lotus.NotesSession COM server's typelibs for installs
    my ($self) = @_;

    print STDERR "--  Searching the Lotus.NotesSession COM server's typelibs\n"  if $self->{debug};
    my @result;

    # get the COM Server's CLSID
    my $com_clsid = $Registry->{'Classes/Lotus.NotesSession/CLSID//'}
        or die 'Lotus Notes COM Server not found in registry';

    # get the CLSID of its typelib key
    my $typelib_clsid = $Registry->{"Classes/CLSID/$com_clsid/TypeLib//"}
        or die 'TypeLib for Lotus Notes COM Server not found in registry';

    # search all available typelib versions for paths
    my $typelib = $Registry->{"Classes/TypeLib/$typelib_clsid/"};
    foreach my $key (keys %$typelib) {
        if ($self->{debug}) {
            (my $version = $key) =~ s|/$||;
            print STDERR "--   Searching typelib version $version\n";
        }
        if (my $path = $typelib->{$key . '0/win32//'}) {
            $path =~ s/[^\\]*$//;  # remove program
            print STDERR "--    Found $path\n"  if $self->{debug};
            push @result, _normalize_path($path);
        }
        if (my $path = $typelib->{$key . 'HELPDIR//'}) {
            print STDERR "--    Found $path\n"  if $self->{debug};
            push @result, _normalize_path($path);
        }
    }
    return @result;
}


# utility class methods ------------------------------------------------------

sub _normalize_path {
    # append backslash, lowercase
    my ($path) = @_;
    $path .= '\\' unless $path =~ /\\$/;
    return lc $path;
}


1;


=head1 NAME

Config::LotusNotes - Access Lotus Notes configuration

=head1 VERSION

This documentation refers to C<Config::LotusNotes> 0.21.

=head1 SYNOPSIS

  $factory = Config::LotusNotes->new();

  # access default installation
  $conf = $factory->default_configuration();
  $data = $conf->get_environment_value('Directory');
  $conf->set_environment_value('$NotesEnvParameter', 'value');

  # find all installations 
  @installs = $factory->get_all_configurations();

=head1 DESCRIPTION

C<Config::LotusNotes> gives you a view of your local Lotus Notes/Domino 
installations from the filesystem perspective.
Its main purpose is to read and manipulate the main Notes configuration file, 
F<notes.ini>. 

The module can handle multiple installations.

You can use it to

 - enumerate local Notes/Domino installations
 - gather basic information about your local Notes/Domino installations 
 - exchange data with Lotus Notes via the environment functions.

A C<Config::LotusNotes> object searches the Windows registry for Lotus Notes
installations, which can then be accessed in their representations as 
L<Config::LotusNotes::Configuration|Config::LotusNotes::Configuration> objects.

=head2 The Lotus Notes environment

The Lotus Notes environment is often used to store local user preferences 
and to share information between separate parts of an application. 

The Lotus Notes formula language has the C<@Environment> and C<@SetEnvironment>
functions and the C<ENVIRONMENT> keyword to access the program's environment.
Lotus script uses the C<GetEnvironmentValue>, C<GetEnvironmentString>,
C<SetEnvironmentVar> and C<Environ> functions for that purpose.
The Lotus Notes environment is stored in the F<notes.ini> file, which is 
instantly updated after each change to the environment. 
This allows you to communicate data to external programs.

Unfortunately, Lotus Notes does not recognize external changes to 
F<notes.ini> while it is running. 
If you need to push data to a running instance of Lotus Notes, you can use the 
environment functions of the corresponding OLE object as shown in L<SEE ALSO>.
There might be problems with simultaneous programmatic and user access 
to the same Lotus Notes session.  

=head1 METHODS

=over 4

=item new();

Constructor, returns a C<Config::LotusNotes> object that can give you
L<Config::LotusNotes::Configuration|Config::LotusNotes::Configuration> objects
via its default_configuration() and all_configurations() methods.

=item default_configuration();

Returns a L<Config::LotusNotes::Configuration|Config::LotusNotes::Configuration> 
object for the default Lotus Notes installation.
The default installation is the one that is registered in the Windows registry 
as the handler for the C<Notes> class.

If there is only one version of Lotus Notes installed on your machine, 
this is what you want.

This method will throw an 'No Lotus Notes/Domino installation found' exception 
if it cannot find any Lotus Notes installation.

=item all_configurations();

This gives you an array containing a 
L<Config::LotusNotes::Configuration|Config::LotusNotes::Configuration> object 
for each Lotus Notes/Domino installation found on your machine.
If no installation is found, an empty array is returned.
In rare cases, an installation might not be detected. See L<BUGS AND LIMITATIONS> 
for details.

=back

=head1 SEE ALSO

An alternative way of accessing Lotus Notes/Domino is via its OLE and COM 
scripting capabilities. Here is an OLE example:

  use Win32::OLE;

  # print Lotus Notes version:
  $Notes = Win32::OLE->new('Notes.NotesSession')
      or die "Cannot start Notes.NotesSession object.\n";
  ($Version) = ($Notes->{NotesVersion} =~ /\s*(.*\S)\s*$/); # remove blanks
  printf "Running Notes \"%s\" on \"%s\".\n", $Version, $Notes->Platform;

  # write value to environment
  print "Setting $key to $value\n";
  $session->SetEnvironmentVar('$NotesEnvParameter', 'test value');

This will start an instance of Lotus Notes if none is already running.
See the Lotus Notes designer documentation for more information.

=head1 DIAGNOSTICS

Call the constructor method new() with the option C<debug =E<gt> 1> to get 
diagnostic information on the search progress.

=head1 DEPENDENCIES

This module only runs under Mircosoft Windows (tested on Windows NT, 2000 
and XP).
It uses L<Win32::TieRegistry|Win32::TieRegistry> and 
L<Config::IniFiles|Config::IniFiles> (which ist not a standard module.). 
The test require Test::More.

=head1 BUGS AND LIMITATIONS

=head2 Problems locating installations

Lotus Notes/Domino stores information about the installed versions in 
registry keys that are specific  to the main version number only, 
e.g. 5.0, 6.0 and 7.0, with ".0" being fix.
Each additional installation will overwrite the data of any previous 
installation that has the same main version number.

This module works around this problem by searching several additional places 
in the registry for possible installation locations. 
In complex installations this might not find all instances.

Please bear in mind that such complex situations can only be created if you 
cheat the Notes installer by renaming the paths of your existing installations 
before each additional installation.
The normal behaviour of the installer is to force you to update your previous 
installation. 
So in real life, there should be no problem with missed installations.   

=head2 Problems parsing notes.ini

If the F<notes.ini> file is malformed, a warning will be issued and the 
corresponding installation will be skipped by all_configurations()Z<>. 
new() will throw an exception in that case.  

Malformed F<notes.ini> files can be produced by writing multiline values to the
environment, e.g. with code like this: 
C<@SetEnvironment("testvalue"; "A"+@Char(10)+"B")>, which produces two lines, 
the second just containing "B".
A successive read of testvalue will return just "A".

If you run into this kind of problem, check whether all lines except the first 
one are of the pattern C<parameter=value>. 
If not, back up your F<notes.ini> and delete any line with no "=" 
(except the C<[Notes]> line). Try again.

=head1 EXAMPLES

  use Config::LotusNotes;
  $factory = Config::LotusNotes->new();

  # get default LotusNotes installation
  $conf = $factory->default_configuration();
  print 'Lotus Notes ', $conf->version, ' installed in ', $conf->notespath, "\n";

  # retrieving and setting notes.ini values
  # get name of the user's mail file.
  $mail_file = $conf->get_environment_value('MailFile');
  # store a value in notes.ini
  $conf->set_environment_value('$NotesEnvParameter', 'test value');

  # find all installations 
  @all_confs = $factory->all_configurations();

  # print a table with version, type and path of all installations.
  # see demo\FindNotes.pl for an extended version.
  printf "%-8s %-7s %s\n", 'version', 'type', 'path';
  foreach my $conf (@all_confs) {
      printf "%-8s %-7s %s\n", 
          $conf->version, 
          $conf->is_server ? 'server' : 'client', 
          $conf->notespath;
  }

  # filter the list: only servers
  @servers = grep { $_->is_server } @all_confs;

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006 HS - Hamburger Software GmbH & Co. KG.
All rights reserved.

This module is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

This library is distributed in the hope that it will be useful, but 
B<without any warranty>; without even the implied warranty of 
B<merchantibility> or B<fitness for a particular purpose>.

=head1 AUTOR

Harald Albers, netzwerksicherheit@hamburger-software.de

Version 0.1 written 10/2003. See the F<Changes> file for change history.

=cut
