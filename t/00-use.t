use Test::More tests => 7;

BEGIN {
    use_ok('POE');
    use_ok('POE::Component::IRC');
    use_ok('POE::Component::IRC::Plugin::PAUSE::RecentUploads');
    use_ok('POE::Component::IRC::Plugin::CPAN::Info');
    use_ok('POE::Component::IRC::Plugin::Connector');
    use_ok('POE::Component::IRC::Plugin::NickReclaim');
    use_ok('POE::Component::IRC::Plugin::BotAddressed');
}