use MooseX::Declare;
class App::Amylase::CLI::Command::update_feeds extends App::Amylase::CLI::BaseCommand {

  method execute {
    my $schema = $self->get_schema_and_deploy_db_if_needed();


  }
};

__END__

=head1 NAME

App::Amylase::CLI::Command::update_feeds -
