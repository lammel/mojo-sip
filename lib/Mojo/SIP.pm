package Mojo::SIP;

# ABSTRACT: Fusing together Mojolicious and Net::SIP

use Mojo::Base -base;
use Net::SIP::Dispatcher::Mojo;

BEGIN { $Mojo::SIP::VERSION = '0.001' }

sub new { @_ > 1 ? shift->SUPER::new->from_string(@_) : shift->SUPER::new }

sub uac {
    my $self = shift;
    my $uac = Net::SIP::Simple->new(%{@_}, loop => Net::SIP::Dispatcher::Mojo->new);
}

sub uas {
    my $self = shift;
    my $uas = Net::SIP::Simple->new(%{@_}, loop => Net::SIP::Dispatcher::Mojo->new);
    $self->{uas}->listen(
        # filter => sub {},
        cb_create => sub {},        # Callback on accepting the call.
        cb_established => sub {},   # Callback after the call is establishe
        cb_cleanup => sub {},       # Callback called when the call gets closed
    );
    $self->{uas} = $uas;
}

1;

=pod

=head1 NAME

Mojo::SIP - Fusing together Mojo and Net::SIP


=head1 VERSION

version 0.001


=head1 SYNOPSIS

    # regular Net::SIP syntax
    use Mojo::SIP;
    use Net::SIP::Simple;

    # Mojo-style
    use Mojo::SIP;
    use Net::SIP::Simple;

    my $loop = Mojo::IOLoop;
    my $uac  = Mojo::SIP->new(...);
    my $call = $uac->invite(
        'you.uas@example.com',
        cb => sub { $emit->send },
    );

    $loop->on('invited', sub { echo "You are INVITED"})
    $loop->run;


=head1 DESCRIPTION

This module allows you to use L<Mojo::IOLoop> as the event loop for L<Net::SIP>.

L<Net::SIP::Simple> allows you to define the event loop. You can either define
it using L<Net::SIP::Dispatcher::Mojo> manually or you can simply use
L<Mojo::SIP> which will automatically set it for you.

    # doing it automatically and globally
    use Mojo::SIP;
    use Net::SIP::Simple;

    my $ua = Net::SIP::Simple->new(...);
    $ua->register( cb_final => sub { $cv->send } );


You can also call L<Net::SIP>'s C<loop> method in order to keep it as close as
possible to the original syntax. This will internally use L<Mojo>, whether
you're using L<Mojo::SIP> globally or L<Net::SIP::Dispatcher::Mojo>
locally.

    use Mojo::SIP;
    
    my $stopvar;
    my $ua = Mojo::SIP->new(...);
    $ua->register( cb_final => sub { $stopvar++ } );

    # call Net::SIP's event loop runner,
    # which calls Mojo's instead
    $ua->loop( 1, \$stopvar );

=head1 COMPATIBILITY

L<Net::SIP> requires dispatchers (event loops) to check their condition 
valiables (stopvars). L<Mojo::SIP> uses a recurring timer to avoid overhead
in the implemenation of L<NET::SIP>.


=head1 AUTHOR

Roland Lammel <lammel@cpan.org>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Roland Lammel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

