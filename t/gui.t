use ExtUtils::testlib;
use Test::More no_plan;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test', qw( count_results )) };
BEGIN { use_ok('WWW::Search::Lycos') };

my $iDebug = 0;
my $iDump = 0;

&my_engine('Lycos');
# goto TEST_NOW;
&my_test('gui', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
TEST_NOW:
$iDebug = 0;
$iDump = 0;
&my_test('gui', 'disest'.'ablishmentarianistic', 1, 9, $iDebug, $iDump);
# goto ALL_DONE;
$iDebug = 0;
&my_test('gui', 'antidisest'.'ablishmentarianistic', 21, 29, $iDebug, $iDump);
ALL_DONE:
exit 0;

sub my_engine
  {
  my $sEngine = shift;
  $WWW::Search::Test::oSearch = new WWW::Search($sEngine);
  ok(ref($WWW::Search::Test::oSearch), "instantiate WWW::Search::$sEngine object");
  } # my_engine

sub my_test
  {
  # Same arguments as WWW::Search::Test::count_results()
  my ($sType, $sQuery, $iMin, $iMax, $iDebug, $iPrintResults) = @_;
  my $iCount = &count_results(@_);
  cmp_ok($iCount, '>=', $iMin, qq{lower-bound num-hits for $sType query=$sQuery}) if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for $sType query=$sQuery}) if defined $iMax;
  } # my_test

__END__

