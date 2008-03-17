use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
     NAME => 'cpan_bot',
     VERSION_FROM => 'bin/cpan_bot.pl',
     PREREQ_PM => {
     	'Test::More'										=> 0,
     	'Test::Script'										=> 1.02,
        'POE'                                               => 0.9999,
        'POE::Component::IRC'                               => 5.56,
        'POE::Component::IRC::Plugin::PAUSE::RecentUploads' => 0.04,
        'POE::Component::IRC::Plugin::CPAN::Info'           => 0.03,
        'POE::Component::IRC::Plugin::Connector'            => 0,
        'POE::Component::IRC::Plugin::NickReclaim'          => 0,
        'POE::Component::IRC::Plugin::BotAddressed'         => 0,
        'POE::Component::IRC::Plugin::CPAN::LinksToDocs::No404s' => 0.001,
     },
     EXE_FILES => [ 'bin/cpan_bot.pl' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'bin/cpan_bot.pl',
       AUTHOR         => 'Zoffix Znet <zoffix@cpan.org>') : ()),
);