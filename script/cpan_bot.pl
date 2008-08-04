#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '0.11';

use POE qw(
    Component::IRC
    Component::IRC::Plugin::PAUSE::RecentUploads
    Component::IRC::Plugin::CPAN::Info
    Component::IRC::Plugin::Connector
    Component::IRC::Plugin::NickReclaim
    Component::IRC::Plugin::BotAddressed
    Component::IRC::Plugin::CPAN::LinksToDocs::No404s::Remember
    Component::IRC::Plugin::OutputToPastebin
    Component::IRC::Plugin::WWW::CPAN
    Component::IRC::Plugin::WWW::CPANRatings::RSS
);

my $configdir = $ENV{CPAN_BOT_DIR} || '';
if ( !$configdir && $ENV{HOME} ) {
    $configdir = "$ENV{HOME}/.cpan_bot";
}

my $config = do "$configdir/config";
unless ( defined $config ) {
    die "Failed to load config `$configdir/config` ($!) ($@)";
}

my @Channels = @{ $config->{channels} };
my $Do_NickServ = $config->{do_nickserv};
my $NickServ_Pass = $config->{nickserv_pass};
my %PAUSE_Options = @{ $config->{PAUSE_options} || [] };
my @CPANInfo_Options = @{ $config->{CPANInfo_options} || [] };
my @OutputToPastebin_Options
= @{ $config->{OutputToPastebin_options} || [] };

my @CPANLinks_to_docs_options
= @{ $config->{CPANLinks_to_docs_options} || [] };

my @WWW_CPAN_Options = @{ $config->{WWW_CPAN_Options} || [] };

# a little "fix" to make sure PAUSE plugin does not report stuff auto
@PAUSE_Options{qw(fetched_event report_event quiet_flood)}
= ( 'pause_uploads_list_event', 'pause_new_uploads_event', 1 );

my @WWW_CPANRatings_Options = @{ $config->{WWW_CPANRatings_Options} || [] };

my $irc = POE::Component::IRC->spawn(
        nick    => $config->{nick},
        server  => $config->{server},
        port    => $config->{port},
        ircname => $config->{ircname},
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
                irc_msg
                pause_uploads_list
                pause_new_uploads_event
            )
        ],
    ],
);


$poe_kernel->run();

sub _start {
    $irc->yield( register => 'all' );

    $irc->plugin_add(
        'BotAddressed' => POE::Component::IRC::Plugin::BotAddressed->new
    );

    $irc->plugin_add(
        'NickReclaim' => POE::Component::IRC::Plugin::NickReclaim->new
    );

    $_[HEAP]->{connector} = POE::Component::IRC::Plugin::Connector->new;
    $irc->plugin_add(
        'Connector' => $_[HEAP]->{connector}
    );

    $irc->plugin_add(
        'CPANInfo' =>
        POE::Component::IRC::Plugin::CPAN::Info->new(
            @CPANInfo_Options
        )
    );

    $irc->plugin_add(
        'WWW_CPAN' =>
        POE::Component::IRC::Plugin::WWW::CPAN->new(
            @WWW_CPAN_Options
        )
    );

    $irc->plugin_add(
        'WWW_CPAN_Ratings' =>
        POE::Component::IRC::Plugin::WWW::CPANRatings::RSS->new(
            @WWW_CPANRatings_Options
        )
    );

    $irc->plugin_add(
        'CPANLinksToDocs' =>
      POE::Component::IRC::Plugin::CPAN::LinksToDocs::No404s::Remember->new(
            @CPANLinks_to_docs_options
        )
    );

    $irc->plugin_add(
        'Paster' => POE::Component::IRC::Plugin::OutputToPastebin->new(
            @OutputToPastebin_Options
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
                    %PAUSE_Options
                )
        );
    }
    undef;
}

sub irc_public {
    undef; # just to clean up the _default{} from public messages
}

sub pause_uploads_list {
    print "\n[ " . localtime($_[ARG0]->{time}) . "] Fetched new list from PAUSE\n";
}

sub pause_new_uploads_event {
    my $input = $_[ARG0];
    if ( $input->{is_flood} and not $config->{no_pastebins} ) {
        my $total_dists = @{ $input->{formatted_output} };

        my $paste =  make_paste_data( $input->{data} );

        # YES!! WE ARE TALKING TO OURSELVES!!! IS IT WRONG TO BE INSANE?
        # DON"T JUDGE ME :( I"M JUST A BOT! :(
        # but what we are really doing here is making just ONE
        # paste and then we will repeat it to all channels.
        # yes, this was not "tought of" properly while being made,
        # but oh well...
        $irc->yield( privmsg => $irc->nick_name =>
            "Total of $total_dists were uploaded see: "
            . "[irc_to_pastebin]$paste"
        );
    }
}

sub make_paste_data {
    my $data_ref = shift;

    my @dists = sort { $a->{name} cmp $b->{name} }
                    @$data_ref;

    my $longest_dist = 0;
    my $longest_auth = 0;
    for ( @dists ) {
        $longest_dist = length $_->{dist}
            if length $_->{dist} > $longest_dist;

        $longest_auth = length $_->{name}
            if length $_->{name} > $longest_auth;
    }

    $longest_dist += 4; # gimme some white spaces \o/
    $longest_auth += 4;

    my $paste = '+' . '-' x ($longest_dist+5+$longest_auth) . "+\n";

    my $row_sep = "\n|" . '-' x ($longest_dist+2) . '+'
                    . "-" x ($longest_auth+2) . "| \n";

    $paste .= join $row_sep,
        map {
            sprintf "| %*s | %-*s |", $longest_dist, $_->{dist},
                                $longest_auth, $_->{name},
        } @dists;

    $paste .= "\n+" . '-' x ($longest_dist+5+$longest_auth) . "+\n";

    return $paste;
}

sub irc_msg {
    my ( $who, $what ) = @_[ARG0, ARG2];
    if ( (split /!/, $who)[0] eq $irc->nick_name ) {
        #.... then call the crazy house... err. I mean do this:
        $irc->yield( privmsg => $_ => $what ) for @Channels;
    }
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
                        %PAUSE_Options
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

cpan_bot - an IRC CPAN Info bot

=head1 DESCRIPTION

An IRC bot to report recent uploads to PAUSE and provide
information about CPAN authors/distributions/modules, as well
as gives out links to documentation on L<http://search.cpan.org/>

=head1 USAGE

    perl cpan_bot.pl

=head1 CONFIG

The config file is a file containing a simple hashref which the
script will C<do''> default location the script will
look for is ~/.cpan_bot/config however the path can be changed
via enviromental variable C<CPAN_BOT_DIR>, thus config file
will be located at C<"$CPAN_BOT_DIR/config">

The sample config file is as follows:

    {
        nick    => 'CPAN2',
        server  => 'irc.freenode.net',
        port    => 6667,
        ircname => 'CPAN bot',
        no_pastebins => 1,
        
        do_nickserv   => 1,
        nickserv_pass => 'passo-word',
        channels      => [ '#zofbot' ],
        PAUSE_options => [
            store => '/home/zoffix/.cpan_bot/pause.data',
            login   => 'ZOFFIX',
            pass    => 'passo-word',
            interval => 600,
            channels => [ '#zofbot' ],
        ],
        CPANInfo_options => [
            path    => '/home/zoffix/.cpan_bot/',
        ],
        CPANLinks_to_docs_options => [
            obj_args => { db_file => '/home/zoffix/.cpan_bot/links.db' }
        ],
        OutputToPastebin_options => [ max_tries => 10 ],
        WWW_CPANRatings_Options => [
            file => '/home/zoffix/.cpan_bot/cpan_ratings.store',
            channels => [ '#zofbot' ],
        ],
    }

=over 10

=item nick

Bot's nickname. Note: L<POE::Component::IRC::NickReclaim> is used,
thus if C<nick> is taken, bot will use C<nick> with an underscore appended.

=item server

The IRC server to connect to.

=item port

The port of IRC server to connect to.

=item ircname

Whatever it is, will be passed to POE::Component::IRC constructor as
a value for 'ircname'

=item no_pastebins

When too many dists are uploaded plugin will say "Total of this many
dists were uploaded see http://link_to_pastebin/blah"; set
C<no_pastebins> option to a true value if you want to disable pastebinning
of "flood" uploads.

=item do_nickserv

This is was developed for FreeNode IRC network. If set to a true value
will identify with services before joining any channels. Not tested
on any other networks, make sure to set to C<0> if you can't identify
or bot will not join anything.

=item nickserv_pass

Password to use for identification with NickServ. Ignored if
C<do_nickserv> is set to a false value.

=item channels

Takes an arrayref of channels to join.

=item PAUSE_options

Takes an I<arrayref>, this is what to pass to
L<POE::Component::IRC::Plugin::PAUSE::RecentUploads> constructor. Beware
that C<fetched_event>, C<report_event> and C<quiet_flood> options are
overriden by the bot.

=item CPANInfo_options
 
Takes an I<arrayref>, this is what to pass to
L<POE::Component::IRC::Plugin::CPAN::Info> constructor.

=item CPANLinks_to_docs_options

Takes an I<arrayref>, this is what to pass to
L<POE::Component::IRC::Plugin::CPAN::LinksToDocs::No404s::Remember> constructor.

=item OutputToPastebin_options

Takes an I<arrayref>, this is what to pass to
L<POE::Component::IRC::Plugin::OutputToPastebin> constructor

=item WWW_CPAN_Options

Takes an I<arrayref>, this is what to pass
L<POE::Component::IRC::Plugin::WWW::CPAN> constructor.

=back

=head1 SEE ALSO

The functionality can be understood by reading at least the description
of the following PoCo::IRC plugins which this bot uses:

L<POE::Component::IRC::Plugin::PAUSE::RecentUploads>
L<POE::Component::IRC::Plugin::CPAN::Info>
L<POE::Component::IRC::Plugin::Connector>
L<POE::Component::IRC::Plugin::NickReclaim>
L<POE::Component::IRC::Plugin::BotAddressed>
L<POE::Component::IRC::Plugin::CPAN::LinksToDocs::No404s::Remember>
L<POE::Component::IRC::Plugin::OutputToPastebin>
L<POE::Component::IRC::Plugin::WWW::CPAN>

=head1 BUGS

So far none were spotted. Once the bot didn't want to fetch any info
files used by L<POE::Component::IRC::Plugin::CPAN::Info> on a FreeBSD box.
Magically the bug disappeared after a reboot. I blame it on the box, but
if you spot something similiar let me know. Thanks.

=head1 AUTHOR

Zoffix Znet <zoffix@cpan.org>
( L<http://zoffix.com>, L<http://haslayout.net> )

=head1 LICENSE

Same as Perl

=cut