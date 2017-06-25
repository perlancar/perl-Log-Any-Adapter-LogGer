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

sub init {
    my ($self) = @_;
}

for my $method (Log::Any->logging_methods()) {
    make_method(
        $method,
        sub {
            my ($self, $msg) = @_;
            my $cat = $self->{category};
            unless ($LogGer_Objects{$cat}) {
                $LogGer_Objects{$cat} =
                    Log::ger->get_logger(category => $cat);
            }
            my $lg_method = $method;
            $lg_method = "warn" if $lg_method eq 'warning';
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
        sub {1},
    );
}

1;
# ABSTRACT: Send Log::Any logs to Log::ger

=for Pod::Coverage ^(init)$

=head1 SYNOPSIS

 use Log::Any::Adapter;
 Log::Any::Adapter->set('LogGer');


=head1 DESCRIPTION


=head1 SEE ALSO

L<Log::ger>

L<Log::Any>
