package Test::App::Amylase::CLI::Command::deploy_database;
use base 'Test::App::Amylase::CLI::BASE';

use App::Cmd::Tester;
use File::Temp  qw/ tmpnam /;
use Test::More;
use Test::File;

sub base_args {
  my $test = shift;
  my $config_file = $test->{config_file};

  return [ 'deploy_database' , '--configfile' , $config_file ];
}

sub make_database :Tests(5) {
  my $test = shift;

  my $result = test_app( $test->class => $test->base_args );

  my $output = sprintf( 'Created database at %s' , $test->{db_file} );

  is( $result->stdout    , $output , 'notify that database was created' );
  is( $result->stderr    , ''      , 'stderr is empty' );
  is( $result->error     , undef   , 'no exceptions thrown' );
  is( $result->exit_code , 0       , 'clean exit' );

  file_exists_ok( $test->{db_file} );
}

sub make_database_with_existing :Tests(5) {
  my $test = shift;

  my $result = test_app( $test->class => $test->base_args );

  my $error = sprintf( 'ERROR: Refusing to overwrite existing database at %s' , $test->{db_file} );

  is(   $result->stdout    , ''     , 'nothing on stdout' );
  is(   $result->stderr    , $error , 'see expected error message' );
  isnt( $result->exit_code , 0      , 'unclean exit' );

  my $error = $result->error;
  isa_ok( $error , 'App::Cmd::Tester::Exited' );
  is( $$error , 1 );

}

sub make_database_with_existing_and_force :Tests(5) {
  my $test = shift;

  my @args = ( @{$test->base_args} , '--force' );
  my $result = test_app( $test->class => \@args );

  my $output = sprintf( 'Created database at %s' , $test->{db_file} );

  is( $result->stdout    , $output , 'notify that database was created' );
  is( $result->stderr    , ''      , 'stderr is empty' );
  is( $result->error     , undef   , 'no exceptions thrown' );
  is( $result->exit_code , 0       , 'clean exit' );

  file_exists_ok( $test->{db_file} );
}

sub make_database_with_provided_filename :Tests(5) {
  my $test = shift;

  my $db_file = tmpnam() . '.db';
  my @args    = ( @{$test->base_args} , '--database' , $db_file );
  my $result  = test_app( $test->class => \@args );

  my $output = sprintf( 'Created database at %s' , $db_file );

  is( $result->stdout    , $output , 'notify that database was created' );
  is( $result->stderr    , ''      , 'stderr is empty' );
  is( $result->error     , undef   , 'no exceptions thrown' );
  is( $result->exit_code , 0       , 'clean exit' );

  file_exists_ok( $db_file );
  unlink( $db_file );
}

1;
