
use Test::More;

eval "use Test::Script";
plan skip_all => "Test::Script required for testing" if $@;

plan( tests => 1 );
script_compiles_ok( 'bin/cpan_bot.pl', 'bin/cpan_bot.pl compiles');