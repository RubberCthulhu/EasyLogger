
package EasyLogger::Simple;

use strict;
use warnings;

use Exporter;

our @ISA = qw(Exporter);
our $VERSION = "0.1";

sub new {
    my ($class, $path, %opts) = @_;
    my $self = {};
    $class = ref($class) || $class;
    
    return undef unless defined $path;
    $self->{Path} = $path;
    my $mode = exists $opts{Rewrite} && $opts{Rewrite} ? '>' : '>>';
    return undef unless open($self->{Out}, $mode, $self->{Path});
    $self->{Lock} = exists $opts{Lock} ? $opts{Lock} : undef;
    $self->{DateTime} = exists $opts{DateTime} && !$opts{DateTime} ? 0 : 1;
    $self->{StdOut} =  exists $opts{StdOut} && $opts{StdOut} ? 1 : 0;
    $self->{StdErr} =  exists $opts{StdErr} && $opts{StdErr} ? 1 : 0;
    
    bless($self, $class);
    return $self;
}

sub DESTROY {
    my $self = shift;
    close($self->{Out});
}

sub msg {
    my ($self, $msg) = @_;
    
    $self->lock();
    my $text = ($self->{DateTime} ? scalar(localtime())."\t" : "").$msg."\n";
    print {$self->{Out}} $text;
    print STDOUT $text if $self->{StdOut};
    print STDERR $text if $self->{StdErr};
    $self->unlock();
}

sub lock {
    my $self = shift;
    
    $self->{Lock}->lock() if defined $self->{Lock};
}

sub unlock {
    my $self = shift;
    
    $self->{Lock}->unlock() if defined $self->{Lock};
}

1;



