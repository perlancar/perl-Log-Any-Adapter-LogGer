package Log::Any::Adapter::LogGer;

# DATE
# VERSION

use strict;
use warnings;

use Log::ger ();
use Log::Any::Adapter::Util qw(make_method);
use base qw(Log::Any::Adapter::Base);

my %LogGer_Objects; # key = category

my @logging_methods = Log::Any->logging_methods;
my %logging_levels;
for my $i (0..@logging_methods-1) {
    $logging_levels{$logging_methods[$i]} = $i;
}

sub _default_level {
    return $ENV{LOG_LEVEL}
        if $ENV{LOG_LEVEL} && $logging_levels{$ENV{LOG_LEVEL}};
    return 'trace' if $ENV{TRACE};
    return 'debug' if $ENV{DEBUG};
    return 'info'  if $ENV{VERBOSE};
    return 'error' if $ENV{QUIET};
    'warning';
}

sub init {
    my ($self) = @_;
    $self->{min_level} = _default_level() if !defined($self->{min_level});
}

for my $method (Log::Any->logging_methods()) {
    make_method(
        $method,
        sub {
            my $self = shift;
            return if $logging_levels{$method} <
                $logging_levels{ $self->{min_level} };
            my $cat = $self->{category};
            unless ($LogGer_Objects{$cat}) {
                $LogGer_Objects{$cat} =
                    Log::ger::setup_object(category => $cat);
            }
            my $meth = "log_$method";
            $meth = "log_warn" if $meth eq 'log_warning';
            if ($LogGer_Objects{$cat}->can($meth)) {
                $LogGer_Objects{$cat}->$meth(@_);
            }
        });
}

for my $method (Log::Any->detection_methods()) {
    make_method(
        $method,
        sub {
            my $self = shift;
            (my $meth = $method) =~ s/^is_//;
            return $logging_levels{$meth} <
                $logging_levels{ $self->{min_level} };
        });
}

1;
# ABSTRACT: Send Log::Any logs to Log::ger

=for Pod::Coverage init

=head1 SYNOPSIS

 use Log::Any::Adapter;
 Log::Any::Adapter->set('Log::ger');


=head1 DESCRIPTION

This adapter lets you send Log::Any logs to Log::ger.


=head1 SEE ALSO

L<Log::ger>

L<Log::Any>
