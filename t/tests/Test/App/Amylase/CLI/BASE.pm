package Test::App::Amylase::CLI::BASE;
use base 'Test::Class';

use Test::More;
use File::Temp  qw/ tmpnam tempfile /;
use YAML        qw/ DumpFile /;

sub class { 'App::Amylase::CLI' }

sub setup :Tests(startup => 1) {
  my $test = shift;
  use_ok $test->class;
}

sub setup_config :Tests(startup) {
  my $test = shift;

  my( undef , $config_file ) = tempfile( 'configXXXX' ,
                                         SUFFIX => '.yaml' ,
                                         DIR    => '/tmp' ,
                                       );

  my $db_file = tmpnam() . '.db';

  DumpFile( $config_file , { database => $db_file });

  $test->{config_file} = $config_file;
  $test->{db_file}     = $db_file;
}

sub shutdown :Tests(shutdown) {
  my $test = shift;
  unlink $test->{config_file} , $test->{db_file};
}

1;
