package App::Amylase::Schema::Result::Feeds;
use strict;
use warnings;
use 5.010;
use base 'DBIx::Class::Core';

__PACKAGE__->load_components(
  'InflateColumn::DateTime' ,
  'TimeStamp' ,
);

__PACKAGE__->table( 'feeds' );

__PACKAGE__->add_columns(
  id               => { data_type => 'INTEGER'  , is_auto_increment => 1 } ,
  url              => { data_type => 'VARCHAR'  , size => 2048 } ,
  title            => { data_type => 'TEXT'     , } ,
  link             => { data_type => 'VARCHAR'  , size => 2048 } ,
  tagline          => { data_type => 'TEXT'     , is_nullable => 1 } ,
  last_modified    => { data_type => 'DATETIME' , set_on_create => 1 , set_on_update => 1 } ,
  etag             => { data_type => 'TEXT'     , is_nullable => 1 } ,
  last_poll        => { data_type => 'DATETIME' , is_nullable => 1 } ,
  last_good_poll   => { data_type => 'DATETIME' , is_nullable => 1 } ,
  last_poll_status => { data_type => 'VARCHAR'  , is_nullable => 1 , size => 3 } ,
  error_count      => { data_type => 'INTEGER'  , default_value => 0 } ,
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many(
  'items' => 'App::Amylase::Schema::Result::Items' => { 'foreign.feed_id' => 'self.id' } ,
);

1;

__END__

=head1 NAME

App::Amylase::Schema::Feeds - the feeds table

