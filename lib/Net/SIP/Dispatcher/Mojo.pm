package Net::SIP::Dispatcher::Mojo;

# ABSTRACT: Mojo dispatcher for Net::SIP

use Mojo::Base 'Mojo::EventEmitter';
use Mojo::IOLoop;
use Net::SIP::Util 'invoke_callback';
use Log::Any qw($log);

BEGIN { $Net::SIP::Dispatcher::Mojo::VERSION = '0.001' }

has 'sip';
has max_statements => 10;

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = bless {
        _interval => $args{'_interval'} || 0.1,
    }, $class;

    return $self;
}

sub _unwatch {
  my $self = shift;
  return unless delete $self->{watching};
  Mojo::IOLoop->singleton->reactor->remove($self->{handle});
}

sub addFD {
    my $self = shift;
    my ( $fh, $cb_data, $name ) = @_;

    my $fn = fileno $fh or return;
    $self->{'_fd_watchers'}{$fn} = 1;
    Mojo::IOLoop->singleton->reactor->io(
        $fn => sub {
        my $reactor = shift;
     
        invoke_callback( $cb_data, $fh );
        
        # while (my $notify = $sip->pg_notifies) {
        #     $self->emit(notification => @$notify);
        # }
        # 
        # return unless (my $waiting = $self->{waiting}) && $dbh->pg_ready;
        # my ($sth, $cb) = @{shift @$waiting}{qw(sth cb)};
        # 
        # my $result = do { local $dbh->{RaiseError} = 0; $dbh->pg_result };
        # my $err = defined $result ? undef : $dbh->errstr;
        # 
        # $self->$cb($err, Mojo::SIP::Results->new(db => $self, sth => $sth));
        # $self->_next;
        # $self->_unwatch unless $self->backlog || $self->is_listening;
    })->watch($self->{handle}, 1, 0);
}

sub delFD {
    my $self = shift;
    my $fh   = shift;
    my $fn   = fileno $fh or return;

    delete $self->{'_fd_watchers'}{$fn};
    Mojo::IOLoop->singleton->reactor->remove($fn);
}

sub add_timer {
    my $self = shift;
    my ( $when, $cb, $repeat, $name ) = @_;
    defined $repeat or $repeat = 0;

    # is $when epoch or relative?
    if ( $when >= 3600*24*365 ) {
        $when = time() - $when;
    }

    my $timer;
    $timer = Mojo::IOLoop->after($when => sub {
        $log->debug("Invoke initial timer " . $timer . " callback ($when sec passed)") if $log->is_debug;
        invoke_callback( $cb, $self );
        $timer = Mojo::IOLoop->recurring($repeat => sub {
            $log->debug("Invoke recurring timer " . $timer . " callback ($repeat sec passed)") if $log->is_debug;
            invoke_callback( $cb, $self );
        });
    });
    
    return $timer;
}

sub looptime { time() }

sub loop {
    my $self = shift;
    Mojo::IOLoop->run();
}

1;

=pod

=head1 NAME

Net::SIP::Dispatcher::Mojo - Mojo dispatcher for Net::SIP

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This module allows L<Net::SIP> to work with L<Mojo> as the event loop,
instead of its own. This means you can combine them.

While this is the implementation itself, you probably want to use
L<Mojo::SIP> instead. You definitely want to read the documentation there
instead of here. Go ahead, click the link. :)

The rest only documents how the loop implementation works. If you use this
directly, the only method you care about is C<loop>.

=head1 WARNING

The compatible mode of Net::SIP::Dispatcher::Mojo is pretty stressful on
your CPU. Please read the compatibility mode section in L<Mojo::SIP>.

=head1 ATTRIBUTES

=head2 _net_sip_compat

Whether to be fully compatible with L<Net::SIP> with the expense of possible
side-effects on the CPU load of your processes. Please read compatibility mode
in L<Mojo::SIP>.

=head2 _ae_interval

In normal (non-compatible) mode, how often to check for stopvars.
Default: B<0.2> seconds.

=head1 INTERNAL ATTRIBUTES

These attributes have no accessors, they are saved as internal keys.

=head2 _idle

Hold the L<Mojo::AggressiveIdle> object that checks stopvars.

=head2 _stopvar

Condition variables to be checked for stopping the loop.

=head2 _cv

Main condition variable allowing for looping.

=head2 _fd_watchers

All the watched file descriptors.

=head2 _stopvar_timer

Timer holding stopvar checking. Only for default non-compatible mode.

=head1 METHODS

=head2 new

The object constructor. It creates a default CondVar in C<_cv> hash key,
and sets an aggressive idle CondVar in the C<_idle> hash key, which checks
the stopvars every loop cycle.

=head2 addFD($fd, $cb_data, [$name])

Add a file descriptor to watch input for, and a callback to run when it's ready
to be read.

=head2 delFD($fd)

Delete the watched file descriptor.

=head2 add_timer($when, $cb_data, [$repeat], [$name])

Create a timer to run a callback at a certain point in time. If the time is
considerably far (3,600 * 24 * 365 and up), it's a specific point in
time. Otherwise, it's a number of seconds from now.

The C<repeat> option is an optional interval for the timer.

=head2 looptime

Provide the event loop time.

=head2 loop($timeout, [\@stopvars])

Run the event loop and wait for all events to finish (whether by timeout or
stopvars becoming true).

=head1 AUTHOR

Roland Lammel <lammel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Roland Lammel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

