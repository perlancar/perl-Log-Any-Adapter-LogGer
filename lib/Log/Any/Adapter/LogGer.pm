package Log::Any::Adapter::LogGer;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Log::ger ();

use Log::Any;
use Log::Any::Adapter::Util qw(make_method);
use parent qw(Log::Any::Adapter::Base);

my $Time0;

my %LogGer_Objects;

my @logging_methods = Log::Any->logging_methods;
our %logging_levels;
for my $i (0..@logging_methods-1) {
    $logging_levels{$logging_methods[$i]} = $i;
}
# some common typos
$logging_levels{warn} = $logging_levels{warning};

sub _min_level {
    my $self = shift;

    return $ENV{LOG_LEVEL}
        if $ENV{LOG_LEVEL} && defined $logging_levels{$ENV{LOG_LEVEL}};
    return 'trace' if $ENV{TRACE};
    return 'debug' if $ENV{DEBUG};
    return 'info'  if $ENV{VERBOSE};
    return 'error' if $ENV{QUIET};
    $self->{default_level};
}

sub init {
    my ($self) = @_;
    $self->{default_level} //= 'warning';
    $self->{min_level} //= $self->_min_level;
}

for my $method (Log::Any->logging_methods()) {
    make_method(
        $method,
        sub {
            my ($self, $msg) = @_;
            return if $logging_levels{$method} <
                $logging_levels{$self->{min_level}};

            my $cat = $self->{category};
            unless ($LogGer_Objects{$cat}) {
                $LogGer_Objects{$cat} =
                    Log::ger::setup_object(category => $cat);
            }
            my $lg_method = "log_$method";
            $lg_method = "log_warn" if $lg_method eq 'log_warning';
            #if ($LogGer_Objects{$cat}->can($lg_method)) {
            $LogGer_Objects{$cat}->$lg_method($msg);
            #}
        }
    );
}

for my $method (Log::Any->detection_methods()) {
    my $level = $method; $level =~ s/^is_//;
    make_method(
        $method,
        sub {
            my $self = shift;
            $logging_levels{$level} >= $logging_levels{$self->{min_level}};
        }
    );
}

1;
# ABSTRACT: Send Log::Any logs to Log::ger

=for Pod::Coverage ^(init)$

=head1 SYNOPSIS

 use Log::Any::Adapter;
 Log::Any::Adapter->set('LogGer');


=head1 DESCRIPTION


=head1 ENVIRONMENT

=head2 LOG_LEVEL => str

=head2 QUIET => bool

=head2 VERBOSE => bool

=head2 DEBUG => bool

=head2 TRACE => bool

These environment variables can set the default for C<min_level>. See
documentation about C<min_level> for more details.


=head1 SEE ALSO

L<Log::ger>

L<Log::Any>
