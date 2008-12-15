
# $Id: gui.t,v 1.3 2008/12/14 23:59:24 Martin Exp $

use ExtUtils::testlib;
use Test::More no_plan;

use WWW::Search::Test;
BEGIN
  {
  use_ok('WWW::Search::Lycos');
  }

my $iDebug = 0;
my $iDump = 0;

tm_new_engine('Lycos');
# goto TEST_NOW;
tm_run_test('gui', $WWW::Search::Test::bogus_query, 0, 0, $iDebug);
TEST_NOW:
pass;
diag("Sending 1-page query to lycos.com...");
$iDebug = 0;
$iDump = 0;
tm_run_test('gui', 'muu'.'ggle', 1, 9, $iDebug, $iDump);
# goto ALL_DONE;
diag("Sending multi-page query to lycos.com...");
$iDebug = 0;
tm_run_test('gui', 'antidisest'.'ablishmentarianistic', 39, undef, $iDebug, $iDump);
ALL_DONE:
pass;
exit 0;

__END__

