use inc::Module::Install;

name('WWW-Search-Lycos');
version_from('Lycos.pm');
author('Martin Thurn <mthurn@cpan.org>');
license('perl');

requires('HTML::TreeBuilder');
requires('WWW::Search::Test' => 2.21);
# Test::More is needed for `make test`:
include_deps('Test::More', 5.004);
requires('Test::More');

check_nmake();      # check and download nmake.exe for Win32
&Makefile->write;

1;

__END__
