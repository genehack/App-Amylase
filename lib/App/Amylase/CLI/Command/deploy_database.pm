use MooseX::Declare;
class App::Amylase::CLI::Command::deploy_database extends App::Amylase::CLI::BaseCommand {
  use 5.010;

  has force => (
    isa           => 'Bool' ,
    is            => 'rw' ,
    documentation => 'Force overwrite of existing database' ,
    traits        => [ qw( Getopt )] ,
    default       => 0 ,
  );


  method execute {
    my $db = $self->database;

    if ( -e $db ) {
      unless ( $self->force ) {
        say STDERR "ERROR: Refusing to overwrite existing database at $db";
        exit(1);
      }
    }

    $self->deploy_db;
    say "Created database at $db";
  }
};

__END__

=head1 NAME

App::Amylase::CLI::Command::deploy_database -
