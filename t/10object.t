#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More tests => 32;
use WWW::Scraper::ISBN;

###########################################################

my $DRIVER          = 'GoogleBooks';
my $CHECK_DOMAIN    = 'www.google.com';

my %tests = (
    '057122055X' => [
        [ 'is',     'isbn',         '9780571220557'     ],
        [ 'is',     'isbn10',       '057122055X'        ],
        [ 'is',     'isbn13',       '9780571220557'     ],
        [ 'is',     'ean13',        '9780571220557'     ],
        [ 'is',     'title',        'The never-ending days of being dead: dispatches from the frontline of science'            ],
        [ 'is',     'author',       'Marcus Chown'   ],
        [ 'is',     'publisher',    'Faber'    ],
        [ 'is',     'pubdate',      '2007' ],
        [ 'is',     'pages',        '309'               ],
        [ 'is',     'image_link',   'http://bks1.books.google.com/books?id=vZ4KHAAACAAJ&printsec=frontcover&img=1&zoom=1&sig=ACfU3U2z74rrtKn1HpH1GNdj4aFA00baXg' ],
        [ 'is',     'thumb_link',   'http://bks1.books.google.com/books?id=vZ4KHAAACAAJ&printsec=frontcover&img=1&zoom=1&sig=ACfU3U2z74rrtKn1HpH1GNdj4aFA00baXg' ],
        [ 'like',   'description',  qr|Learn how the big bang may have been spawned| ],
        [ 'is',     'book_link',    q|http://books.google.com/books?id=vZ4KHAAACAAJ&source=gbs_ViewAPI| ]
    ],
    '9780571239566' => [
        [ 'is',     'isbn',         '9780571239566'     ],
        [ 'is',     'isbn10',       '0571239560'        ],
        [ 'is',     'isbn13',       '9780571239566'     ],
        [ 'is',     'ean13',        '9780571239566'     ],
        [ 'is',     'title',        'Touching from a Distance: Ian Curtis and Joy Division'  ],
        [ 'is',     'author',       'Deborah Curtis'    ],
        [ 'is',     'publisher',    'Faber and Faber'   ],
        [ 'is',     'pubdate',      '2007'   ],
        [ 'is',     'pages',        240                 ],
        [ 'is',     'image_link',   'http://bks9.books.google.com/books?id=h_sRGgAACAAJ&printsec=frontcover&img=1&zoom=1&sig=ACfU3U2XdlHKLyOC0u8RsirTjjNkWuc9zg' ],
        [ 'is',     'thumb_link',   'http://bks9.books.google.com/books?id=h_sRGgAACAAJ&printsec=frontcover&img=1&zoom=1&sig=ACfU3U2XdlHKLyOC0u8RsirTjjNkWuc9zg' ],
        [ 'like',   'description',  qr|Ian Curtis left behind a legacy rich in artistic genius| ],
        [ 'is',     'book_link',    q|http://books.google.com/books?id=h_sRGgAACAAJ&source=gbs_ViewAPI| ]
    ],
);

my $tests = 0;
for my $isbn (keys %tests) { $tests += scalar( @{ $tests{$isbn} } ) + 2 }


###########################################################

my $scraper = WWW::Scraper::ISBN->new();
isa_ok($scraper,'WWW::Scraper::ISBN');

SKIP: {
	skip "Can't see a network connection", $tests+1   if(pingtest($CHECK_DOMAIN));

	$scraper->drivers($DRIVER);

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

    for my $isbn (keys %tests) {
        $record = $scraper->search($isbn);
        my $error  = $record->error || '';

        SKIP: {
            skip "Website unavailable", scalar(@{ $tests{$isbn} }) + 2   
                if($error =~ /website appears to be unavailable/);

            unless($record->found) {
                diag($record->error);
            }

            is($record->found,1);
            is($record->found_in,$DRIVER);

            my $book = $record->book;
            for my $test (@{ $tests{$isbn} }) {
                if($test->[0] eq 'ok')          { ok(       $book->{$test->[1]},             ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'is')       { is(       $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'isnt')     { isnt(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'like')     { like(     $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); } 
                elsif($test->[0] eq 'unlike')   { unlike(   $book->{$test->[1]}, $test->[2], ".. '$test->[1]' found [$isbn]"); }

            }

            #use Data::Dumper;
            #diag("book=[".Dumper($book)."]");
        }
    }
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    system($cmd);
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}
