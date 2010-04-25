package Test::App::Amylase::CLI::Command::add_feed;
use base 'Test::App::Amylase::CLI::BASE';

use App::Cmd::Tester;
use DateTime;
use File::Temp  qw/ tmpnam /;
use Test::More;
use Test::File;
use XML::Feed;

sub base_args {
  my $test = shift;
  my $config_file = $test->{config_file};

  return [ 'add_feed' , '--configfile' , $config_file ];
}

sub dump_rss_file :Tests(startup) {
  my $test = shift;

  my $feed_file = tmpnam() . '.rss';
  $test->{feed_file} = $feed_file;
  $test->{url} = "file://$feed_file";

  my $feed = XML::Feed->new( 'RSS' );
  $feed->title( 'Test Feed' );
  $feed->base( 'http://example.com' );
  $feed->link( $test->{url} );
  $feed->tagline( 'Testing feeds for fun and profit since 2008' );
  $feed->author( 'Alan Smithee' );

  my $dt = DateTime->new( year => 2008 , month => 1 , day => 10 ,
                          hour => 12 , minute => 0 , second => 0 );
  $feed->modified( $dt );

  open( OUT , '>' , $feed_file )
    or die @_;
  print OUT $feed->as_xml;
  close( OUT );

}

sub add_feed :Tests(4) {
  my $test = shift;

  my $args   = [ @{ $test->base_args} , $test->{url} ];
  my $result = test_app( $test->class => $args );

  my $output = sprintf( 'Added feed %s' , $test->{url} );
  is( $result->stdout    , $output , 'notify that feed was added' );
  is( $result->stderr    , ''      , 'stderr is empty' );
  is( $result->error     , undef   , 'no exceptions thrown' );
  is( $result->exit_code , 0       , 'clean exit' );

}

sub add_feed_again :Tests(5) {
  my $test = shift;

  my $args   = [ @{ $test->base_args} , $test->{url} ];
  my $result = test_app( $test->class => $args );

  my $error = "You're already subscribed to that feed!";
  is( $result->stdout    , ''     , 'stdout is empty' );
  is( $result->stderr    , $error , 'expected error on stderr' );
  is( $result->exit_code , 1      , 'unclean exit' );

  my $error = $result->error;
  isa_ok( $error , 'App::Cmd::Tester::Exited' );
  is( $$error , 1 );
}

sub shutdown :Tests(shutdown) {
  my $test = shift;
  unlink $test->{feed_file};
}

1;
