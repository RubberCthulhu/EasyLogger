
package EasyLogger::Lock::SysVSem;

use strict;
use warnings;

use Exporter;
use IPC::Semaphore;
use IPC::SysV qw(ftok IPC_PRIVATE S_IRUSR S_IWUSR IPC_CREAT IPC_EXCL SEM_UNDO);
use Errno qw(EEXIST);
use EasyLogger::Lock;

our @ISA = qw(EasyLogger::Lock Exporter);
our $VERSION = "0.1";

use constant MAX_TRIES => 10;

sub new {
    my ($class, $path, $id, $count, $n) = shift;
    $class = ref($class) || $class;
    
    my $self = $class->SUPER::new() or return undef;
    
    unless( defined $path ) {
        $self->{SemCount} = 1;
        $self->{SemNum} = 0;
        $self->{SemSet} = IPC::Semaphore->new(
            IPC_CREAT,
            $self->{SemCount},
            S_IRUSR|S_IWUSR|IPC_CREAT
        ) or return undef;
        $self->{SemSet}->setall(1);
    }
    else {
        $self->{SemCount} = 1 unless defined $count;
        $self->{SemNum} = 0 unless defined $n;
        my $key;
        if( defined $id ) {
            $key = IPC::SysV::ftok($path, $id);
        }
        else {
            $key = IPC::SysV::ftok($path);
        }
        $self->{SemSet} = IPC::Semaphore->new(
            $key,
            $self->{SemCount},
            S_IRUSR|S_IWUSR|IPC_CREAT|IPC_EXCL
        );
        unless( defined $self->{SemSet} ) {
            if( $!{EEXIST} ) {
                $self->{SemSet} = IPC::Semaphore->new(
                    $key,
                    $self->{SemCount},
                    S_IRUSR|S_IWUSR
                ) or return undef;
                my $loop = 1;
                for( my $i = 0 ; $i < MAX_TRIES && $loop ; $i++ ) {
                    my $stat = $self->{SemSet}->stat();
                    if( $stat->otime != 0 ) {
                        $loop = 0;
                    }
                    else {
                        sleep(1);
                    }
                }
                
            }
        }
    }
    
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY() if $self->can('SUPER::DESTROY');
}

sub free {
    my $self = shift;
    $self->{SemSet}->remove();
}

sub lock {
    my $self = shift;
    return $self->{SemSet}->op($self->{SemNum}, -1, SEM_UNDO);
}

sub unlock {
    my $self = shift;
    return $self->{SemSet}->op($self->{SemNum}, 1, SEM_UNDO);
}

1;
