use Test::More tests => 8;

BEGIN {
    use_ok('POE');
    use_ok('POE::Component::IRC');
    use_ok('POE::Component::IRC::Plugin::PAUSE::RecentUploads');
    use_ok('POE::Component::IRC::Plugin::CPAN::Info');
    use_ok('POE::Component::IRC::Plugin::Connector');
    use_ok('POE::Component::IRC::Plugin::NickReclaim');
    use_ok('POE::Component::IRC::Plugin::BotAddressed');
    use_ok('POE::Component::IRC::Plugin::CPAN::LinksToDocs::No404s');
}