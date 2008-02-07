use strict;
use warnings;

use POE qw(
    Component::IRC
    Component::IRC::Plugin::PAUSE::RecentUploads
    Component::IRC::Plugin::CPAN::Info
    Component::IRC::Plugin::Connector
    Component::IRC::Plugin::NickReclaim
    Component::IRC::Plugin::BotAddressed
);

my @Channels = ( '#zofbot'  );

## CUSTOMIZE THESE
my $Do_NickServ = 0; # set to 1 to enable identify with NickServ
my $NickServ_Pass = 'NICKSERV_PASS';
my @PAUSE_Options = (
    login   => 'PAUSE_LOGIN',
    pass    => 'PAUSE_PASSWORD',
    interval => 600,
    channels => \@Channels,
);
my @CPANInfo_Options = (
);

my $irc = POE::Component::IRC->spawn(
        nick    => 'CPAN2',
        server  => 'irc.freenode.net',
        port    => 6667,
        ircname => 'CPAN bot by Zoffix',
) or die "Oh noes :( $!";

POE::Session->create(
    package_states => [
        main => [
            qw(
                _start
                irc_001
                _default
                lag_o_meter
                irc_notice
                irc_public
                irc_bot_addressed
            )
        ],
    ],
);


$poe_kernel->run();

sub _start {
    my $heap = $_[HEAP];
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'BotAddressed' => POE::Component::IRC::Plugin::BotAddressed->new
    );

    $irc->plugin_add(
        'NickReclaim' => POE::Component::IRC::Plugin::NickReclaim->new
    );

    $heap->{connector} = POE::Component::IRC::Plugin::Connector->new;
    $irc->plugin_add(
        'Connector' => $heap->{connector}
    );

    $irc->plugin_add(
        'CPANInfo' =>
        POE::Component::IRC::Plugin::CPAN::Info->new(
            @CPANInfo_Options
        )
    );

    $irc->yield( connect => { } );

    $_[KERNEL]->delay( 'lag_o_meter' => 60 );
    undef;
}

sub irc_001 {
    my ( $kernel, $sender ) = @_[ KERNEL, SENDER ];

    unless ( $Do_NickServ ) {
        $kernel->post( $sender => join => $_ )
            for @Channels;

        $irc->plugin_add(
            'PAUSE' =>
                POE::Component::IRC::Plugin::PAUSE::RecentUploads->new(
                    @PAUSE_Options
                )
        );
    }
    undef;
}

sub irc_public {
    undef; # just to clean up the _default{} from public messages
}

sub irc_bot_addressed {
    my ($kernel,$heap,$sender) = @_[ KERNEL, HEAP, SENDER ];
    my ($nick) = ( split /!/, $_[ARG0] )[0];
    my ($channel) = $_[ARG1]->[0];
    my ($what) = $_[ARG2];

    if ( $what =~ /^source(?: \s* code )?\s*$/i ) {
        $kernel->post( $sender => privmsg => $channel =>
            "$nick, my source can be found in "
                . "http://search.cpan.org/~zoffix/ (under cpan_bot-*)"
        );
    }
}

sub irc_notice {
    my ($kernel, $sender, $who, $what) = @_[KERNEL, SENDER, ARG0, ARG2];
    if ( $Do_NickServ and $who eq 'NickServ!NickServ@services.' ) {
        if ( $what eq 'This nickname is owned by someone else' ) {
            $kernel->post( $sender => privmsg => 'NickServ' =>
                'identify ' . $NickServ_Pass
            );
        }
        elsif ( $what eq 'Password accepted - you are now recognized' ) {
            print "\nIdentified with NickServ\n\n";
            $kernel->post( $sender => join => $_ ) for @Channels;
            $irc->plugin_add(
                'PAUSE' =>
                    POE::Component::IRC::Plugin::PAUSE::RecentUploads->new(
                        @PAUSE_Options
                    )
            );
        }
    }

    undef;
}

sub lag_o_meter {
    my ($kernel,$heap) = @_[KERNEL,HEAP];
    print STDOUT "Time: " . time()
                    . " Lag: " . $heap->{connector}->lag() . "\n";
    $kernel->delay( 'lag_o_meter' => 60 );
    undef;
}

sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    my @output = ( "$event: " );

    foreach my $arg ( @$args ) {
        if ( ref($arg) eq 'ARRAY' ) {
                push( @output, "[" . join(" ,", @$arg ) . "]" );
        } else {
                push ( @output, "'$arg'" );
        }
    }
    print STDOUT join ' ', @output, "\n";
    return 0;
}

=head1 NAME

cpan_bot.pl - an IRC CPAN Info bot

=head1 DESCRIPTION

An IRC bot to report recent uploads to PAUSE and provide
information about CPAN authors/distributions/modules.

=head1 USAGE

    perl cpan_bot.pl

=head1 CONFIG

Edit the source:

    my @Channels = ( '#zofbot'  );

    ## CUSTOMIZE THESE
    my $Do_NickServ = 0; # set to 1 to enable identify with NickServ
    my $NickServ_Pass = 'NICKSERV_PASS';
    my @PAUSE_Options = (
        login   => 'PAUSE_LOGIN',
        pass    => 'PAUSE_PASSWORD',
        interval => 600,
        channels => \@Channels,
    );
    my @CPANInfo_Options = (
    );


C<@PAUSE_Options> is what to pass to
L<POE::Component::IRC::Plugin::PAUSE::RecentUploads> constructor.
L<@CPANInfo_Options> is what to pass to
L<POE::Component::IRC::Plugin::CPAN::Info> constructor.

=head1 AUTHOR

Zoffix Znet <zoffix@cpan.org>

( L<http://zoffix.com>, L<http://haslayout.net> )

=head1 LICENSE

Same as Perl
