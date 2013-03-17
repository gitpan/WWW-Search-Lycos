
# $Id: basic.t,v 1.12 2013/03/17 13:18:29 martin Exp $

use warnings;
use strict;

use constant DEBUG_CONTENTS => 0;

use blib;
use ExtUtils::testlib;
use Test::More 'no_plan';
use WWW::Search::Test;

BEGIN
  {
  use_ok('WWW::Search::Lycos');
  }

tm_new_engine('Lycos');

my $iDebug = 0;
my $iDump = 0;
my @ao;

goto CONTENTS if DEBUG_CONTENTS;

# This test returns no results (but we should not get an HTTP error):
diag("Sending bogus query to lycos.com...");
tm_run_test('normal', 'asdfjkersladfkse;oirjsdlkfjleijladsjflkjelrfkilj', 0, 0, $iDebug);

CONTENTS:
pass;
diag("Sending query to lycos.com...");
$iDebug = DEBUG_CONTENTS ? 2 : 0;
$iDump = 0;
# It's almost impossible for a query to return only one page of
# results, because of auto-generated results
tm_run_test('normal', 'dumblesnor'.'ifically', 1, 9, $iDebug, $iDump);
# Look at some actual results:
@ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got any results');
foreach my $oResult (@ao)
  {
  next unless ref($oResult);
  like($oResult->url, qr{\Ahttp://},
       'result URL is http');
  cmp_ok($oResult->title, 'ne', '',
         'result title is not empty');
  cmp_ok($oResult->description, 'ne', '',
         'result description is not empty');
  } # foreach

goto ALL_DONE if DEBUG_CONTENTS;
diag("Sending multi-page query to lycos.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('normal', 'the lovely Britney Spears', 21, undef, $iDebug, $iDump);

ALL_DONE:
pass;

__END__

