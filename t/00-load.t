#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Amylase' ) || print "Bail out!";
}

diag( "Testing App::Amylase $App::Amylase::VERSION, Perl $], $^X" );
