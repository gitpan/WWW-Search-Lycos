use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME' => 'WWW::Search::Lycos',
              'VERSION_FROM' => 'lib/WWW/Search/Lycos.pm',
              'PREREQ_PM' => {
                              'URI' => 1.09,
                              'WWW::Search' => 2.13,
                             },
);

