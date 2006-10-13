use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME          => 'Config::LotusNotes',
    VERSION       => '0.22',
    ABSTRACT_FROM => 'lib/Config/LotusNotes.pm',
    AUTHOR        => 'Harald Albers <albers@cpan.org>',
    PREREQ_PM     => {
        Win32::TieRegistry => 0,
        Config::IniFiles   => 0,
    },
);
