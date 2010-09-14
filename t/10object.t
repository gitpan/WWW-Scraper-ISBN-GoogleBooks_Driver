#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 31;
use WWW::Scraper::ISBN;

###########################################################

my $CHECK_DOMAIN = 'www.google.com';

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", 30   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers("GoogleBooks");

    # this ISBN doesn't exist
	my $isbn = "1234512345";
    my $record;

    eval { $record = $scraper->search($isbn); };
    if($@) {
        like($@,qr/Invalid ISBN specified/);
    }
    elsif($record->found) {
        ok(0,'Unexpectedly found a non-existent book');
    } else {
		like($record->error,qr/Failed to find that book on|website appears to be unavailable/);
    }

	$isbn   = "057122055X";
	$record = $scraper->search($isbn);
    my $error  = $record->error || '';

    SKIP: {
        skip "Website unavailable", 14   if($error =~ /website appears to be unavailable/);

        unless($record->found) {
            diag("ERROR: [$isbn] ".$record->error);
        }
        
        {
            is($record->found,1);
            is($record->found_in,'GoogleBooks');

            my $book = $record->book;
            is($book->{'isbn'},         '9780571220557'         ,'.. isbn found');
            is($book->{'isbn10'},       '057122055X'            ,'.. isbn10 found');
            is($book->{'isbn13'},       '9780571220557'         ,'.. isbn13 found');
            is($book->{'ean13'},        '9780571220557'         ,'.. ean13 found');
            is($book->{'title'},        'The never-ending days of being dead: dispatches from the frontline of science' ,'.. title found');
            is($book->{'author'},       'Marcus Chown'          ,'.. author found');
            is($book->{'book_link'},    'http://books.google.com/books?id=vZ4KHAAACAAJ&source=gbs_ViewAPI');
            is($book->{'image_link'},   'http://bks1.books.google.com/books?id=vZ4KHAAACAAJ&printsec=frontcover&img=1&zoom=1&sig=ACfU3U2z74rrtKn1HpH1GNdj4aFA00baXg');
            is($book->{'thumb_link'},   'http://bks1.books.google.com/books?id=vZ4KHAAACAAJ&printsec=frontcover&img=1&zoom=1&sig=ACfU3U2z74rrtKn1HpH1GNdj4aFA00baXg');
            is($book->{'publisher'},    'Faber'                 ,'.. publisher found');
            is($book->{'pubdate'},      '2007'                  ,'.. pubdate found');
            is($book->{'pages'},        '309'                   ,'.. pages found');
        }
    }

	$isbn   = "9780571239566";
	$record = $scraper->search($isbn);
    $error  = $record->error || '';

    SKIP: {
        skip "Website unavailable", 15   if($error =~ /website appears to be unavailable/);

        unless($record->found) {
            diag("ERROR: [$isbn] ".$record->error);
        }
        
        {
            is($record->found,1);
            is($record->found_in,'GoogleBooks');

            my $book = $record->book;
            is($book->{'isbn'},         '9780571239566'         ,'.. isbn found');
            is($book->{'isbn10'},       '0571239560'            ,'.. isbn10 found');
            is($book->{'isbn13'},       '9780571239566'         ,'.. isbn13 found');
            is($book->{'ean13'},        '9780571239566'         ,'.. ean13 found');
            is($book->{'author'},       q|Deborah Curtis|       ,'.. author found');
            like($book->{'title'},      qr|Touching from a Distance|    ,'.. title found');
            is($book->{'book_link'},    q|http://books.google.com/books?id=h_sRGgAACAAJ&source=gbs_ViewAPI|);
            is($book->{'image_link'},   'http://bks9.books.google.com/books?id=h_sRGgAACAAJ&printsec=frontcover&img=1&zoom=1&sig=ACfU3U2XdlHKLyOC0u8RsirTjjNkWuc9zg');
            is($book->{'thumb_link'},   'http://bks9.books.google.com/books?id=h_sRGgAACAAJ&printsec=frontcover&img=1&zoom=1&sig=ACfU3U2XdlHKLyOC0u8RsirTjjNkWuc9zg');
            like($book->{'description'},qr|Ian Curtis left behind a legacy rich in artistic genius|);
            is($book->{'publisher'},    'Faber and Faber'       ,'.. publisher found');
            is($book->{'pubdate'},      '2007'                  ,'.. pubdate found');
            is($book->{'pages'},        240                     ,'.. pages found');

            #use Data::Dumper;
            #diag("book=[".Dumper($book)."]");
        }
    }
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    system("ping -q -c 1 $domain >/dev/null 2>&1");
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}
