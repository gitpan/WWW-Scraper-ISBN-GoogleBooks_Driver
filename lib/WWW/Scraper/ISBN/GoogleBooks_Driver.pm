package WWW::Scraper::ISBN::GoogleBooks_Driver;

use strict;
use warnings;

use vars qw($VERSION @ISA);
$VERSION = '0.08';

#--------------------------------------------------------------------------

=head1 NAME

WWW::Scraper::ISBN::GoogleBooks_Driver - Search driver for Google Books online book catalog.

=head1 SYNOPSIS

See parent class documentation (L<WWW::Scraper::ISBN::Driver>)

=head1 DESCRIPTION

Searches for book information from Google Books online book catalog

=cut

#--------------------------------------------------------------------------

###########################################################################
# Inheritence

use base qw(WWW::Scraper::ISBN::Driver);

###########################################################################
# Modules

use WWW::Mechanize;
use JSON;

###########################################################################
# Constants

use constant	SEARCH	=> 'http://books.google.com/books?jscmd=viewapi&callback=bookdata&bibkeys=ISBN:';
use constant	LB2G    => 453.59237;   # number of grams in a pound (lb)
use constant	OZ2G    => 28.3495231;  # number of grams in an ounce (oz)
use constant	IN2MM   => 25.4;        # number of inches in a millimetre (mm)

#--------------------------------------------------------------------------

###########################################################################
# Public Interface

=head1 METHODS

=over 4

=item C<search()>

Creates a query string, then passes the appropriate form fields to the 
GoogleBooks server.

The returned page should be the correct catalog page for that ISBN. If not the
function returns zero and allows the next driver in the chain to have a go. If
a valid page is returned, the following fields are returned via the book hash:

  isbn          (now returns isbn13)
  isbn10        
  isbn13
  ean13         (industry name)
  author
  title
  book_link
  image_link
  pubdate
  publisher
  description   (if available)
  pages         (if known)

The book_link and image_link refer back to the GoogleBooks website.

=back

=cut

sub search {
	my $self = shift;
	my $isbn = shift;
    my $data;
	$self->found(0);
	$self->book(undef);

	my $mech = WWW::Mechanize->new();
    $mech->agent_alias( 'Linux Mozilla' );

    eval { $mech->get( SEARCH . $isbn ) };
    return $self->handler("GoogleBooks website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

    my $json = $mech->content();

    return $self->handler("Failed to find that book on GoogleBooks website.")
	    if($json eq 'bookdata({});');

    $json =~ s/^bookdata\(//;
    $json =~ s/\);$//;

    my $code = decode_json($json);
#use Data::Dumper;
#print STDERR "\n# code=".Dumper($code);

    return $self->handler("Failed to find that book on GoogleBooks website.")
	    unless($code->{'ISBN:'.$isbn});

    $data->{url} = $code->{'ISBN:'.$isbn}{info_url};

    return $self->handler("Failed to find that book on GoogleBooks website.")
	    unless($data->{url});

    eval { $mech->get( $data->{url} ) };
    return $self->handler("GoogleBooks website appears to be unavailable.")
	    if($@ || !$mech->success() || !$mech->content());

	# The Book page
    my $html = $mech->content();
    $json =~ s/&#39;/'/;

	return $self->handler("Failed to find that book on GoogleBooks website. [$isbn]")
		if($html =~ m!Sorry, we couldn't find any matches for!si);

#use Data::Dumper;
#print STDERR "\n# " . Dumper($data);
#print STDERR "\n# html=[$html]\n";

    my ($publisher)                     = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?Publisher(?:</span>)?</td><td class="metadata_value">(?:<span[^>]*>)?([^<]+)(?:</span>)?</td>!i;
    ($data->{publisher},$data->{pubdate})   = split(qr/\s*,\s*/,$publisher);

    my ($isbns)                         = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?ISBN(?:</span>)?</td><td class="metadata_value">(?:<span[^>]*>)?([^<]+)(?:</span>)?</td>!i;
    my (@isbns)                         = split(qr/\s*,\s*/,$isbns);
    for my $value (@isbns) {
        $data->{isbn13} = $value    if(length $value == 13);
        $data->{isbn10} = $value    if(length $value == 10);
    }

#use Data::Dumper;
#print STDERR "\n# isbns=[$isbns]";
#print STDERR "\n# " . Dumper($data);

    ($data->{image})                    = $html =~ m!<div class="bookcover"><img src="([^"]+)" alt="Front Cover" title="Front Cover"[^>]+></div>!i;
    ($data->{thumb})                    = $html =~ m!<div class="bookcover"><img src="([^"]+)" alt="Front Cover" title="Front Cover"[^>]+></div>!i;
    ($data->{author})                   = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?Author(?:</span>)?</td><td class="metadata_value">(.*?)</td>!i;
    ($data->{title})                    = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?Title(?:</span>)?</td><td class="metadata_value">(?:<span[^>]*>)?([^<]+)(?:</span>)?!i;
    ($data->{description})              = $html =~ m!<meta name="description" content="([^"]+)" */>!si;
    ($data->{pages})                    = $html =~ m!<td class="metadata_label">(?:<span[^>]*>)?Length(?:</span>)?</td><td class="metadata_value">(?:<span[^>]*>)?(\d+) pages(?:</span>)?</td>!s;
    
    # remove HTML tags
    for(qw(author)) {
        next unless(defined $data->{$_});
        $data->{$_} =~ s!<[^>]+>!!g;
    }

	# trim top and tail
	for(keys %$data) { next unless(defined $data->{$_});$data->{$_} =~ s/^\s+//;$data->{$_} =~ s/\s+$//; }

	my $bk = {
		'ean13'		    => $data->{isbn13},
		'isbn13'		=> $data->{isbn13},
		'isbn10'		=> $data->{isbn10},
		'isbn'			=> $data->{isbn13},
		'author'		=> $data->{author},
		'title'			=> $data->{title},
		'book_link'		=> $mech->uri(),
		'image_link'	=> $data->{image},
		'thumb_link'	=> $data->{thumb},
		'pubdate'		=> $data->{pubdate},
		'publisher'		=> $data->{publisher},
		'description'   => $data->{description},
		'pages'		    => $data->{pages},
	};

#use Data::Dumper;
#print STDERR "\n# book=".Dumper($bk);

    $self->book($bk);
	$self->found(1);
	return $self->book;
}

1;

__END__

=head1 REQUIRES

Requires the following modules be installed:

L<WWW::Scraper::ISBN::Driver>,
L<WWW::Mechanize>
L<JSON>

=head1 SEE ALSO

L<WWW::Scraper::ISBN>,
L<WWW::Scraper::ISBN::Record>,
L<WWW::Scraper::ISBN::Driver>

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please send an email to barbie@cpan.org or submit a bug to the
RT system (http://rt.cpan.org/Public/Dist/Display.html?Name=WWW-Scraper-ISBN-GoogleBooks_Driver).
However, it would help greatly if you are able to pinpoint problems or even
supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  Miss Barbell Productions, <http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2010-2012 Barbie for Miss Barbell Productions

  This module is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut
