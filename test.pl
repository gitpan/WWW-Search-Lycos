# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use ExtUtils::testlib;

use Test::More tests => 16;

BEGIN { use_ok('WWW::Search') };
BEGIN { use_ok('WWW::Search::Test', qw( count_results )) };
BEGIN { use_ok('WWW::Search::Lycos') };

# Fake out WWW::Search::Test
$WWW::Search::Test::oSearch = new WWW::Search('Lycos');
ok(ref($WWW::Search::Test::oSearch), 'instantiate WWW::Search::Lycos object');

my $debug = 0;
my $iCount;

# This test returns no results (but we should not get an HTTP error):
&my_test('normal', $WWW::Search::Test::bogus_query, 0, 0, $debug);

&my_test('normal', 'disest'.'ablishmentarianistic', 1, 9, $debug);
&my_test('normal', 'antidisest'.'ablishmentarianistic', 21, 29, $debug);

GUI_TEST:
&my_test('gui', $WWW::Search::Test::bogus_query, 0, 0, $debug);
&my_test('gui', 'disest'.'ablishmentarianistic', 1, 9, $debug);
&my_test('gui', 'antidisest'.'ablishmentarianistic', 21, 29, $debug);


sub my_test
  {
  # Same arguments as WWW::Search::Test::count_results()
  my ($sType, $sQuery, $iMin, $iMax, $iDebug, $iPrintResults) = @_;
  my $iCount = &count_results(@_);
  cmp_ok($iCount, '>=', $iMin, qq{lower-bound num-hits for query=$sQuery}) if defined $iMin;
  cmp_ok($iCount, '<=', $iMax, qq{upper-bound num-hits for query=$sQuery}) if defined $iMax;
  } # my_test


__END__

