use ExtUtils::MakeMaker;
WriteMakefile(
              'NAME' => 'WWW::Search::Lycos',
              'VERSION_FROM' => 'Lycos.pm',
              'PREREQ_PM' => {
                              'HTML::TreeBuilder' => 0,
                              'WWW::Search::Test' => 2.21,
                             },
             );
