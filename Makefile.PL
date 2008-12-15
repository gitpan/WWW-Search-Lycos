use inc::Module::Install;

all_from('lib/WWW/Search/Lycos.pm');
author('Martin Thurn <mthurn@cpan.org>');
license('perl');

requires('perl' => 5.004);
requires('HTML::TreeBuilder');
requires('WWW::Search::Test' => 2.21);
build_requires('Test::More');

check_nmake();      # check and download nmake.exe for Win32
&Makefile->write;

print STDERR <<"ENDOFNOTE";

NOTE: The author of this module finds that www.lycos.com is extremely unreliable.
A test that fails might succeed if you run it again a few seconds later.
As long as you don't get ALL zero results, it's probably safe to install this module.

ENDOFNOTE

1;

__END__

