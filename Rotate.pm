
package EasyLogger::Rotate;

use strict;
use warnings;

use Exporter;
use EasyLogger::Simple;

our @ISA = qw(EasyLogger::Simple Exporter);
our $VERSION = "0.1";

use constant DEFAULT_TIMEOUT => 60*60;

sub new {
    my ($class, $path_prefix, %opts) = @_;
    $class = ref($class) || $class;
    
    return undef unless defined $path_prefix;
    my $path;
    my $func = exists $opts{CreatePathFunc} ? $opts{CreatePathFunc} : \&create_default_path;
    $path = $func->($path_prefix);
    my $self = $class->SUPER::new($path, %opts) or return undef;
    
    $self->{PathPrefix} = $path_prefix;
    $self->{RotateTimeout} = exists $opts{RotateTimeout} ? $opts{RotateTimeout} : DEFAULT_TIMEOUT;
    $self->{RotateTime} = undef;
    $self->calc_rotate_time();
    $self->{CreatePathFunc} = $func;
    
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->SUPER::DESTROY() if $self->can('SUPER::DESTROY');
}

sub msg {
    my ($self, $msg) = @_;
    my $path;
    
    $self->lock();
    my $now = time();
    if( $now >= $self->{RotateTime} ) {
        $path = $self->create_path();
        $self->close_output();
        return undef unless $self->init_output($path);
        $self->calc_rotate_time();
    }
    $self->unlock();
    
    return $self->SUPER::msg($msg);
}

sub calc_rotate_time {
    my $self = shift;
    
    $self->{RotateTime} = time() + $self->{RotateTimeout};
}

sub create_path {
    my $self = shift;
    
    return $self->{CreatePathFunc}->($self->{PathPrefix});
}

sub create_default_path {
    my ($path_prefix) = @_;
    
    my @time = localtime();
    my $path = $path_prefix.
        sprintf("%.4d%.2d%.2d_%.2d%.2d%.2d",
            $time[5]+1900, $time[4]+1, $time[3],
            $time[2], $time[1], $time[0]);
    
    return $path;
}

1;
