#!/usr/bin/perl -w

use strict;

use EasyLogger;

my $log = new EasyLogger(
    'test.log',
    Level => 'debug',
    StdOut => 1,
    Rewrite => 1,
);

$log->trace("Trace message");
$log->debug("Debug message");
$log->info("Info message");
$log->warning("Warning message");
$log->error("Error message");
$log->fatal("Fatal message");
$log->log("Log message");

exit;



