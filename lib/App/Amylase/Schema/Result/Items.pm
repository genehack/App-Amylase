package App::Amylase::Schema::Result::Items;
use strict;
use warnings;
use 5.010;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
  'InflateColumn::DateTime' ,
  'TimeStamp' ,
);

__PACKAGE__->table( 'items' );

__PACKAGE__->add_columns(
  id            => { data_type => 'INTEGER'  , is_auto_increment => 1 } ,
  unique_id     => { data_type => 'TEXT'     , } ,
  feed_id       => { data_type => 'INTEGER'  , is_foreign_key => 1 } ,
  last_modified => { data_type => 'DATETIME' , set_on_create => 1 , set_on_update => 1 } ,
  timestamp     => { data_type => 'DATETIME' } ,
  date          => { data_type => 'DATE'     } ,
  link          => { data_type => 'VARCHAR'  , size => 2048 } ,
  title         => { data_type => 'TEXT'     } ,
  content       => { data_type => 'TEXT'     } ,
  author        => { data_type => 'TEXT'     } ,
  state         => { data_type => 'VARCHAR'  , size => 10 } ,
  diff          => { data_type => 'TEXT'     } ,
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to(
  'feed' => 'App::Amylase::Schema::Result::Feeds' => { 'foreign.id' => 'self.feed_id' } ,
);

1;

__END__

=head1 NAME

App::Amylase::Schema::Items - the items table
