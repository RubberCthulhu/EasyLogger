
package EasyLogger::Lock::SysVSem;

use strict;
use warnings;

use Exporter;
use IPC::Semaphore;
use EasyLogger::Lock;

our @ISA = qw(EasyLogger::Lock Exporter);
our $VERSION = "0.1";

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    
    my $self = $class->SUPER::new();
    
    return $self;
}

sub DESTROY {
    my $self = shift;
}

sub lock {
    my $self = shift;
}

sub unlock {
    my $self = shift;
}

1;
