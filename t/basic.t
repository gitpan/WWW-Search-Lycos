use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test') };
BEGIN { use_ok('WWW::Search::Lycos') };

&tm_new_engine('Lycos');

my $iDebug = 0;
my $iDump = 0;
my @ao;

# goto TEST_NOW;

# This test returns no results (but we should not get an HTTP error):
diag("Sending bogus query to lycos.com...");
&tm_run_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
TEST_NOW:
diag("Sending 1-page query to lycos.com...");
$iDebug = 0;
$iDump = 0;
TODO:
  {
  local $TODO = q{www.lycos.com is broken, _often_ chokes on any query};
  &tm_run_test('normal', 'disest'.'ablishmentarianistic', 1, 9, $iDebug, $iDump);
  # Look at some actual results:
  @ao = $WWW::Search::Test::oSearch->results();
  cmp_ok(0, '<', scalar(@ao), 'got any results');
  } # end of TODO block
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
TODO:
  {
  local $TODO = q{www.lycos.com is broken, never returns more than 20 hits};
  diag("Sending multi-page query to lycos.com...");
  $iDebug = 0;
  $iDump = 0;
  &tm_run_test('normal', 'the lovely Britney Spears', 21, undef, $iDebug, $iDump);
  } # end of TODO block

ALL_DONE:
exit 0;

__END__

