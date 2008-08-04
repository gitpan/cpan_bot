use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
     NAME => 'cpan_bot',
     VERSION_FROM => 'script/cpan_bot.pl',
     PREREQ_PM => {
     	'Test::More'										=> 0,
     	'Test::Script'										=> 1.02,
        'POE'                                               => 0.9999,
        'POE::Component::IRC'                               => 5.56,
        'POE::Component::IRC::Plugin::PAUSE::RecentUploads' => 0.05,
        'POE::Component::IRC::Plugin::CPAN::Info'           => 0.03,
        'POE::Component::IRC::Plugin::Connector'            => 0,
        'POE::Component::IRC::Plugin::NickReclaim'          => 0,
        'POE::Component::IRC::Plugin::BotAddressed'         => 0,
        'POE::Component::IRC::Plugin::OutputToPastebin'		=> 0.001,
        'POE::Component::IRC::Plugin::WWW::CPAN' 			=> 0.0101,
        'POE::Component::IRC::Plugin::WWW::CPANRatings::RSS' => 0.0101,
  'POE::Component::IRC::Plugin::CPAN::LinksToDocs::No404s::Remember' => 0.001,
     },
     EXE_FILES => [ 'script/cpan_bot.pl' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'script/cpan_bot.pl',
       AUTHOR         => 'Zoffix Znet <zoffix@cpan.org>') : ()),
);
