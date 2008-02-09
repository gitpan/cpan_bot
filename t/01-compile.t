
use Test::More;

eval "use Test::Script";
plan skip_all => "Test::Script required for testing" if $@;

plan( tests => 1 );
script_compiles_ok( 'cpan_bot.pl', 'cpan_bot.pl compiles');