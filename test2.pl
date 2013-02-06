#!/usr/bin/perl -w

use strict;

use EasyLogger;

my $log = new EasyLogger(
    'test.log',
    Level => 'debug',
    StdOut => 1,
    Rewrite => 1,
    Rotate => 'minutely',
);

for( 1..1000 ) {
    $log->info("Info message");
    sleep(10);
}

exit;



