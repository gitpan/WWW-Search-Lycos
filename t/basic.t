use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test', qw( count_results )) };
BEGIN { use_ok('WWW::Search::Lycos') };

&my_engine('Lycos');

my $iDebug = 0;
my $iDump = 0;

# goto TEST_NOW;

# This test returns no results (but we should not get an HTTP error):
diag("Sending bogus query to lycos.com...");
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
TEST_NOW:
diag("Sending 1-page query to lycos.com...");
$iDebug = 0;
$iDump = 0;
&my_test('normal', 'disest'.'ablishmentarianistic', 1, 9, $iDebug, $iDump);
cmp_ok(0, '<', $WWW::Search::Test::oSearch->approximate_hit_count,
       'approximate_hit_count');
cmp_ok($WWW::Search::Test::oSearch->approximate_hit_count, '<=', 9,
       'approximate_hit_count');
# Look at some actual results:
my @ao = $WWW::Search::Test::oSearch->results();
cmp_ok(0, '<', scalar(@ao), 'got any results');
foreach my $oResult (@ao)
  {
  like($oResult->url, qr{\Ahttp://},
       'result URL is http');
  cmp_ok($oResult->title, 'ne', '',
         'result title is not empty');
  cmp_ok($oResult->description, 'ne', '',
         'result description is not empty');
  cmp_ok($oResult->size, 'ne', '',
         'result size is not empty');
  cmp_ok($oResult->change_date, 'ne', '',
         'result change_date is not empty');
  } # foreach
# goto ALL_DONE;
diag("Sending 2-page query to lycos.com...");
$iDebug = 0;
$iDump = 0;
&my_test('normal', 'sq'.'irtle AND warto'.'rtle', 11, 19, $iDebug, $iDump);
cmp_ok(11, '<=', $WWW::Search::Test::oSearch->approximate_hit_count,
       'approximate_hit_count');
cmp_ok($WWW::Search::Test::oSearch->approximate_hit_count, '<=', 19,
       'approximate_hit_count');
TODO:
  {
  local $TODO = q{www.lycos.com is broken, never returns more than 20 hits};
  diag("Sending multi-page query to lycos.com...");
  $iDebug = 0;
  $iDump = 0;
  &my_test('normal', 'the lovely Britney Spears', 21, undef, $iDebug, $iDump);
  cmp_ok(21, '<', $WWW::Search::Test::oSearch->approximate_hit_count,
         'approximate_hit_count');
  } # end of TODO block

ALL_DONE:
exit 0;

sub my_engine
  {
  my $sEngine = shift;
  $WWW::Search::Test::oSearch = new WWW::Search($sEngine);
  ok(ref($WWW::Search::Test::oSearch), "instantiate WWW::Search::$sEngine object");
  $WWW::Search::Test::oSearch->env_proxy('yes');
  } # my_engine

sub my_test
  {
  # Same arguments as WWW::Search::Test::count_results()
  my ($sType, $sQuery, $iMin, $iMax, $iDebug, $iPrintResults) = @_;
  my $iCount = &count_results(@_);
  cmp_ok($iMin, '<=', $iCount, qq{lower-bound num-hits for $sType query=$sQuery}) if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for $sType query=$sQuery}) if defined $iMax;
  } # my_test


__END__

