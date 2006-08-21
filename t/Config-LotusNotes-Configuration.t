use strict;
use warnings;
use Test::More;

# expected number of tests
plan tests => 11;
#plan 'no_plan';

# load module
BEGIN { use_ok('Config::LotusNotes'); }
BEGIN { use_ok('Config::LotusNotes::Configuration'); }
my $VERSION = '0.21';

# do we test the expected version?
is($Config::LotusNotes::Configuration::VERSION, $VERSION, "version = $VERSION");

# all methods available?
can_ok('Config::LotusNotes::Configuration', qw(
    new 
    notesini  notespath  datapath 
    version   is_client  is_server
    get_environment_value set_environment_value
));

# constructor for the factory object
my $factory = Config::LotusNotes->new;

# get default configuration
ok(my $conf = $factory->default_configuration, 'get default configuration');
isa_ok($conf, 'Config::LotusNotes::Configuration');

# test some attributes
like($conf->version(), qr/^\d+\.\d+(\.\d+)?[a-z]?$/, 'version looks OK');
isnt($conf->is_server(), $conf->is_client(), 'is_server and is_client differ');

# reading, writing and deleting information
is($conf->get_environment_value('$testthewest'        ), undef,  'read undefined key');
ok($conf->set_environment_value('$testthewest', 'test'),         'store key' );
is($conf->get_environment_value('$testthewest'        ), 'test', 'verify key');
ok($conf->set_environment_value('$testthewest', undef ),         'delete key');
is($conf->get_environment_value('$testthewest'        ), undef,  'verify key');
