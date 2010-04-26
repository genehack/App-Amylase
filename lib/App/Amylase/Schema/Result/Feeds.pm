package App::Amylase::Schema::Result::Feeds;
use strict;
use warnings;
use 5.010;
use base 'DBIx::Class::Core';

use DateTime;
use Date::Parse;
use Digest::SHA1    qw/ sha1_hex /;
use HTML::StripScripts::Parser;
use XML::Feed;

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
  etag             => { data_type => 'TEXT'     , is_nullable => 1 } ,
  last_modified    => { data_type => 'INTEGER'  , is_nullable => 1 } ,
  last_poll        => { data_type => 'INTEGER'  , is_nullable => 1 } ,
  last_good_poll   => { data_type => 'INTEGER'  , is_nullable => 1 } ,
  last_poll_status => { data_type => 'VARCHAR'  , is_nullable => 1 , size => 3 } ,
  content_sha1     => { data_type => 'VARCHAR'  , is_nullable => 1 , size => 255 } ,
  error_count      => { data_type => 'INTEGER'  , default_value => 0 } ,
  updated          => { data_type => 'DATETIME' , set_on_create => 1 , set_on_update => 1 } ,
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many(
  'items' => 'App::Amylase::Schema::Result::Items' => { 'foreign.feed_id' => 'self.id' } ,
);

sub poll {
  my( $self ) = @_;

  my $time = time();

  my $response = _fetch_url( $self->url );
  $self->last_poll( $time );
  $self->last_poll_status( $response->code );

  die $response->status_line
    unless( $response->is_success );

  ### FIXME this needs to distinguish between temp and perm redirects
  $self->_update_url_based_on_redirects( $response )
    if ( $response->redirects );

  $self->last_good_poll( $time );
  $self->_process_successful_response( $response );

  $self->insert()
}

sub _process_entry {
  my( $self , $entry ) = @_;

  my $return = {
    feed_id   => $self->id ,
    unique_id => $entry->id ,
  };

  $return->{content} = _process_content( $entry );

  foreach ( qw/ title author link / ) {
    $return->{$_} = _process_entry_item( $entry , $_ );
  }

  $return->{date} = _process_entry_date( $entry , $self->last_good_poll );

  return $return;
}

sub _process_successful_response {
  my( $self , $response ) = @_;

  return unless $self->_update_modification_data( $response );

  my $parsed_feed_obj = _parse_response_into_feed( $response );
  $self->_update_feed_meta_data( $parsed_feed_obj );

  my $items_rs = $self->result_source->schema->resultset( 'Items' );

  my( @entries ) = $parsed_feed_obj->entries;
 ENTRY: foreach my $entry ( @entries ) {
    my $processed_entry = $self->_process_entry( $entry );
    $processed_entry->{feed_id} = $self->id;

    if( my $item = $items_rs->find({ unique_id => $processed_entry->unique_id })) {
      $item->potentially_update_item( $processed_entry );
    }
    else {
      my $item = $items_rs->create( $processed_entry );
      $item->update();
    }
  }
}

sub _update_feed_meta_data {
  my( $self , $parsed_feed ) = @_;

  ## nasty kludge to strip html from titles
  my $title = $parsed_feed->title || $self->url;
  $title =~ s/<(?:[^>'"]*|(['"]).*?\1)*>//gs;
  $title =~ s/\n//g;

  $self->set_columns({
    title   => $title ,
    link    => $parsed_feed->link    || '' ,
    tagline => $parsed_feed->tagline || '' ,
  });
}


sub _update_modification_data {
  my( $self , $response ) = @_;

  if ( my $last_mod = $response->header( 'Last-Modified' )) {
    my $epoch = str2time( $last_mod );
    return 0 if $self->last_modified and $epoch == $self->last_modified;
    $self->last_modified( $epoch );
  }
  elsif ( my $etag = $response->header('ETag')) {
    return 0 if $self->etag and $self->etag eq $etag;
    $self->etag( $etag );
  }
  elsif ( my $content = $response->decoded_content({ default_charset => 'utf8'})) {
    my $sha = sha1_hex( $content );
    return 0 if $self->content_sha1 and $self->content_sha1 eq $sha;
    $self->content_sha1( $sha );
  }
  # else we can't tell if it's changed, so we have to assume it has.
  return 1;
}

sub _update_url_based_on_redirects {
  my( $self , $response ) = @_;

  my @redirects = $response->redirects;
  $self->url( $redirects[-1] );
}

sub _fetch_url {
  my( $url ) = @_;

  state $ua = LWP::UserAgent->new();
  $ua->timeout(10);

  return $ua->get( $url );
}

sub _parse_response_into_feed {
  my( $response ) = @_;

  if( my $content = $response->decoded_content({ default_charset => 'utf8' })) {
    $content = decode( 'utf8' , $content )
      unless ( utf8::is_utf8( $content ));

    return XML::Feed->parse( \$content );
  }
}

my $hss = HTML::StripScripts::Parser->new(
  {
    Context     => 'Flow' ,
    AllowSrc    => 1      ,
    AllowHref   => 1      ,
  },
  attr_encoded   => 1,
  strict_names   => 1,
);

sub _process_content {
  my( $entry ) = @_;

  my $content = $hss->filter_html( $entry->content->body );

  # feedburner seems to like to change ID params in it's URLs which causes
  # stuff to get marked as unread even though it hasn't really
  # changed. they also use webbug images.
  ## suck on this you feedburner schmucks.

  # gosh, it's not just feedburner. let's have a whole list of fucktard URLs to remove:
  my @bad_guys = (
    'http://ad.doubleclick.net' ,
    'http://feed(ads|proxy).googleadservices.com' ,
    'http://feeds.feedburner.com' ,
    'http://stats.wordpress.com' ,
    'http://www.pheedo.com' ,
  );

  foreach my $asshole ( @bad_guys ) {
    $content =~ s[<img.*?src="$asshole.*?/\s*>][]g;
    $content =~ s[<a.*?href="$asshole.*?>.*?</a>][]g ;
  }

  # okay, i know, let's randomly insert long runs of spaces into our feed
  # and then next time strip them back out. grrrrrrr.
  $content =~ s[  +][ ]g;

  return $content;
}

sub _process_entry_item {
  my( $entry , $item ) = @_;

  ### FIXME also here. seriously, WTF.
  my $item_content = $entry->$item;

  if ( $item_content ) {
    decode_entities( $item_content );
    encode_entities( $item_content , '&' );
  }

  return $item_content;
}

sub _process_entry_date {
  my( $entry , $date ) = @_;

  my $time;
  if ( $entry->issued ) {
    $time = $entry->issued->epoch;
  } elsif ( $entry->modified ) {
    $time = $entry->modified->epoch;
  } else {
    $time = $date;
  }

  return $time;
}

1;

__END__

=head1 NAME

App::Amylase::Schema::Feeds - the feeds table

