use MooseX::Declare;
class App::Amylase::CLI::Command::deploy_database extends App::Amylase::CLI::BaseCommand {

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
        $self->usage_error( "Refusing to overwrite existing database" );
      }
    }

    $self->deploy_db;
  }
};

__END__

=head1 NAME

App::Amylase::CLI::Command::deploy_database -
