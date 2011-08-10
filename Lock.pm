
package EasyLogger::Lock;

use strict;
use warnings;

use Exporter;

our @ISA = qw(Exporter);
our $VERSION = "0.1";

sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $self = {};
    
    bless($self, $class);
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
