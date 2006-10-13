package Config::LotusNotes::Configuration;
use strict;
#use warnings;
use Carp;
use Config::IniFiles;

our $VERSION = '0.22';


# constructor ----------------------------------------------------------------

sub new {
    my ($classname, %options) = @_;
    my $path = $options{path} or die 'no notes install path specified';
    $path =~ s/\\$//;

    # basic checks of the directory and its content
    my $notesexe = $path.'\\nlnotes.exe';
    my $notesini = $path.'\\notes.ini';
    croak "Notes install path not found: $path" unless -d $path;
    croak "No Notes binary found in $path"      unless -f $notesexe;
    croak "No notes.ini found in $path"         unless -f $notesini;

    # Create and store object for easy access to inifile values.
    # There might be invalid lines in R6 notes.ini. 
    my $inifile = Config::IniFiles->new(-file => $notesini) 
        or croak "Error parsing $notesini";
    my $self = bless {
        notespath => $path,
        notesini  => $notesini,
        inifile   => $inifile,
    }, $classname;
    return $self;
}


# public accessors -----------------------------------------------------------

sub notesini  { return shift->{notesini }}
sub notespath { return shift->{notespath}}
sub datapath  { return shift->get_environment_value('Directory')}

sub is_server { return shift->get_environment_value('KitType') == 2 }
sub is_client { return shift->get_environment_value('KitType') == 1 }

sub version {
    my ($self) = @_;
    return $self->{version} if $self->{version};  # cached value

    # try to extract the version from one of these files
    my @files_with_version = qw(nsd.exe ndgts.dll ninotes.dll memcheck.exe nnntp);
    foreach my $file (@files_with_version) {
        my $filepath = $self->notespath . "\\" . $file;
        next unless -f $filepath;
        open FILE, "< $filepath" or next; # skip errors.
        while (<FILE>) {
            # we cache the result in order to avoid repeated file access.
            return $self->{version} = $2  if /(Release (\d+\.\d+(\.\d+)?[a-z]?))/
        }
        close FILE;
    }
    croak 'could not determine notes version';
}


# public methods -------------------------------------------------------------

sub get_environment_value {
	my ($self, $key) = @_;
	return $self->{inifile}->val("Notes", $key);
}


sub set_environment_value {
	my ($self, $key, $value) = @_;
	if ($self->{inifile}->val("Notes", $key)) {
		$self->{inifile}->setval("Notes", $key, $value) or return;
	} 
	else {
		$self->{inifile}->newval("Notes", $key, $value) or return;
	}
	return $self->{inifile}->WriteConfig($self->{notesini});
}


1;


=head1 NAME

Config::LotusNotes::Configuration - Represents one Lotus Notes/Domino configuration

=head1 VERSION

This documentation refers to C<Config::LotusNotes::Configuration> 0.22, 
released Oct 13, 2006.

=head1 SYNOPSIS

  $factory = Config::LotusNotes->new();

  # access default installation
  $conf = $factory->default_configuration();

  # basic information about a configuration
  print "Version: ", $conf->version, "\n";
  print "This is a server.\n" if $conf->is_server;

  # getting and setting environment values
  $data = $conf->get_environment_value('Directory');
  $conf->set_environment_value('$NotesEnvParameter', 'value');

=head1 DESCRIPTION

A C<Config::LotusNotes::Configuration> object represents the configuration
of a local Lotus Notes/Domino installation from the view of the file system.
It lets you read and modify the Lotus Notes configuration file, F<notes.ini>,
where Notes stores its environment. 
See L<Config::LotusNotes/"The Lotus Notes environment"> 
for more information on exchanging data with Lotus Notes via the Notes environment. 

C<Config::LotusNotes::Configuration> objects also give you access to some 
basic information like install paths and the Notes version number.

To create these objects, use the 
L<default_configuration()|Config::LotusNotes/item_default_configuration> and 
L<all_configurations()|Config::LotusNotes/item_default_configuration>
methods of L<Config::LotusNotes|Config::LotusNotes>.

=head1 PROPERTIES

=over 4

=item notespath();

Returns the path where the program files are stored.

=item datapath();

Returns the path where the data files are stored.

=item notesini();

Returns the full path (including file name) of the F<notes.ini> file.

=item version();

Returns the Lotus Notes version number, e.g. 7.0 or 5.0.13a.

=item is_client();

Returns true if the configuration belongs to a client (workstation) installation.

=item is_server();

Returns true if the configuration belongs to a server installation.

=back

=head1 METHODS

=over 4

=item new(path => $path);

Constructor, returns a C<Config::LotusNotes::Configuration> object 
representing the installation at the specified path. 

The recommended way to create C<Config::LotusNotes::Configuration> 
objects is to use the
L<default_configuration()|Config::LotusNotes/item_default_configuration> and 
L<all_configurations()|Config::LotusNotes/item_default_configuration>
methods of L<Config::LotusNotes|Config::LotusNotes>.

=item get_environment_value($item_name);

Gets the value of the parameter named C<$item_name> from F<notes.ini>.
If there is no such parameter, C<undef> is returned.

In order to access values that were written by Lotus Notes via the environment 
functions, prefix the parameter name with "$".

=item set_environment_value($item_name, $value);

Writes a parameter/value pair to F<notes.ini>.
If the entry exists, it will be updated with the new value.
If the value is C<undef>, the whole entry is removed.

If you want the parameter to be accessible to Lotus Notes via the environment 
functions, prefix its name with "$".

=back

=head1 BUGS AND LIMITATIONS

See L<Config::LotusNotes/"BUGS AND LIMITATIONS">.

=head1 EXAMPLES

See L<Config::LotusNotes/EXAMPLES>.

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006 HS - Hamburger Software GmbH & Co. KG.
All rights reserved.

This module is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

This library is distributed in the hope that it will be useful, but 
without any warranty; without even the implied warranty of 
merchantibility or fitness for a particular purpose.

=head1 AUTOR

Harald Albers, albers@cpan.org

Version 0.1 written 10/2003. See the F<Changes> file for change history.

=cut
