# As we do not know how many installs the current machine really has,
# we only do some very basic tests.

use strict;
use warnings;
use Test::More;

# expected number of tests
plan tests => 8;
#plan 'no_plan';

# load module
BEGIN { use_ok('Config::LotusNotes'); }
my $VERSION = '0.21';

# do we test the expected version?
is($Config::LotusNotes::VERSION, $VERSION, "version = $VERSION");

# all methods available?
can_ok('Config::LotusNotes', qw(new default_configuration all_configurations));

# constructor for the factory object
ok(my $factory = Config::LotusNotes->new, 'constructor');
isa_ok($factory, 'Config::LotusNotes');

# get default configuration
ok(my $conf = $factory->default_configuration, 'get default configuration');
isa_ok($conf, 'Config::LotusNotes::Configuration');

# get all installs. We only test the first configuration.
my @all_confs = $factory->all_configurations();
ok(@all_confs > 0, 'At least one install found');
isa_ok($all_confs[0], 'Config::LotusNotes::Configuration');
