use ExtUtils::MakeMaker;

WriteMakefile(
     NAME => 'cpan_bot',
     VERSION_FROM => 'cpan_bot.pl',
     PREREQ_PM => {
        'POE'                                               => 0.9999,
        'POE::Component::IRC'                               => 5.56,
        'POE::Component::IRC::Plugin::PAUSE::RecentUploads' => 0.01,
        'POE::Component::IRC::Plugin::CPAN::Info'           => 0.03,
        'POE::Component::IRC::Plugin::Connector'            => 0,
        'POE::Component::IRC::Plugin::NickReclaim'          => 0,
        'POE::Component::IRC::Plugin::BotAddressed'         => 0,
     },
     AUTHOR => 'Zoffix Znet <cpan@zoffix.com>',
     EXE_FILES => [ 'cpan_bot.pl' ],
);