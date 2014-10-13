# NAME

Mojo::SIP - Fusing together Mojo and Net::SIP

# VERSION

version 0.001

# SYNOPSIS

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

# DESCRIPTION

This module allows you to use [Mojo::IOLoop](https://metacpan.org/pod/Mojo::IOLoop) as the event loop for [Net::SIP](https://metacpan.org/pod/Net::SIP).

[Net::SIP::Simple](https://metacpan.org/pod/Net::SIP::Simple) allows you to define the event loop. You can either define
it using [Net::SIP::Dispatcher::Mojo](https://metacpan.org/pod/Net::SIP::Dispatcher::Mojo) manually or you can simply use
[Mojo::SIP](https://metacpan.org/pod/Mojo::SIP) which will automatically set it for you.

    # doing it automatically and globally
    use Mojo::SIP;
    use Net::SIP::Simple;

    my $ua = Net::SIP::Simple->new(...);
    $ua->register( cb_final => sub { $cv->send } );

You can also call [Net::SIP](https://metacpan.org/pod/Net::SIP)'s `loop` method in order to keep it as close as
possible to the original syntax. This will internally use [Mojo](https://metacpan.org/pod/Mojo), whether
you're using [Mojo::SIP](https://metacpan.org/pod/Mojo::SIP) globally or [Net::SIP::Dispatcher::Mojo](https://metacpan.org/pod/Net::SIP::Dispatcher::Mojo)
locally.

    use Mojo::SIP;
    
    my $stopvar;
    my $ua = Mojo::SIP->new(...);
    $ua->register( cb_final => sub { $stopvar++ } );

    # call Net::SIP's event loop runner,
    # which calls Mojo's instead
    $ua->loop( 1, \$stopvar );

# COMPATIBILITY

[Net::SIP](https://metacpan.org/pod/Net::SIP) requires dispatchers (event loops) to check their condition 
valiables (stopvars). [Mojo::SIP](https://metacpan.org/pod/Mojo::SIP) uses a recurring timer to avoid overhead
in the implemenation of [NET::SIP](https://metacpan.org/pod/NET::SIP).

# AUTHOR

Roland Lammel <lammel@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Roland Lammel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
