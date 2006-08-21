use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'Config::LotusNotes',
    VERSION       => '0.21',
    ABSTRACT_FROM => 'lib/Config/LotusNotes.pm',
    AUTHOR        => 'Harald Albers <netzwerksicherheit@hamburger-software.de>',
    PREREQ_PM     => {
    	# If you include standard modules in this list, ppm will complain about
    	# them not being installed even if they are.
        # Test::More         => 0,
        # Win32::TieRegistry => 0,
        Config::IniFiles     => 0,
    },
);
