use MooseX::Declare;
class App::Amylase::CLI::Command::add_feed extends App::Amylase::CLI::BaseCommand {
  use 5.010;
  use Try::Tiny;

  method validate_args ( $opts , $args ) {
    $self->usage_error( "Need at least one feed" )
      unless @$args;

    $self->usage_error( "One feed at a time, please" )
      unless @$args eq 1;
  }

  method execute ( $opts , $args ) {
    my $url = $args->[0];

    my $schema = $self->get_schema_and_deploy_db_if_needed;
    my $feeds_rs = $schema->resultset( 'Feeds' );

    if ( $feeds_rs->find({ url => $url })) {
      say STDERR "You're already subscribed to that feed!";
      exit 1;
    }

    my $feed = $feeds_rs->new({ url => $url });
    try {
      $feed->poll;

      $feed->insert;

      say "Added feed $url";
    }
    catch { say $_ ; exit 1 }

  }
};

__END__

=head1 NAME

App::Amylase::CLI::Command::add_feed -
