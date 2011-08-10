
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
    return undef unless open($self->{Out}, '>>', $self->{Path});
    $self->{Lock} = exists $opts{Lock} ? $opts{Lock} : undef;
    $self->{DateTime} = exists $opts{DateTime} && $opts{DateTime} ? 1 : 0;
    
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
    print {$self->{Out}} ($self->{DateTime} ? scalar(localtime()) : "").$msg."\n";
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



