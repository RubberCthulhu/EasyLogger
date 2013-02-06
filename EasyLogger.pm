
package EasyLogger;

use strict;
use warnings;

require Exporter;
use Carp;
use IO::Handle;
use DateTime;

our @ISA = qw(Exporter);
our $VERSION = "0.5";
our @EXPORT = qw();
our @EXPORT_OK = qw();

use constant LEVEL_TRACE   => 0x10;
use constant LEVEL_DEBUG   => 0x20;
use constant LEVEL_INFO    => 0x30;
use constant LEVEL_WARNING => 0x40;
use constant LEVEL_ERROR   => 0x50;
use constant LEVEL_FATAL   => 0x60;
use constant LEVEL_NONE    => 0x100;

our %NAME_LEVEL_MAP = (
    'trace'   => LEVEL_TRACE,
    'debug'   => LEVEL_DEBUG,
    'info'    => LEVEL_INFO,
    'warning' => LEVEL_WARNING,
    'error'   => LEVEL_ERROR,
    'fatal'   => LEVEL_FATAL,
    'none'    => LEVEL_NONE,
);

our %LEVEL_NAME_MAP = map { $NAME_LEVEL_MAP{$_} => $_ } keys(%NAME_LEVEL_MAP);

our $DEFAULT_LEVEL = LEVEL_NONE;

our %LEVEL_PREFIX = (
    LEVEL_TRACE,   'TRACE',
    LEVEL_DEBUG,   'DEBUG',
    LEVEL_INFO,    'INFO',
    LEVEL_WARNING, 'WARN',
    LEVEL_ERROR,   'ERROR',
    LEVEL_FATAL,   'FATAL',
    LEVEL_NONE,    '',
);

our $PREFIX_LENGTH = 7;

our %ROTATE_TYPES = (
    'const'    => 1,
    'minutely' => 2,
    'hourly'   => 3,
    'daily'    => 4,
    'monthly'  => 5,
    'yearly'   => 6,
);

our $DEFAULT_ROTATE = 'const';

sub new {
    my ($class, $path, %opt) = @_;
    $class = ref($class) || $class;
    
    return undef unless defined $path;
    
    my $self = bless({} => $class);
    
    $self->{Path} = undef;
    $self->{ConstPath} = $path;
    $self->{Out} = undef;
    $self->{IsOpen} = undef;
    $self->{DateTime} = exists $opt{DateTime} && !$opt{DateTime} ? 0 : 1;
    $self->{StdOut} =  exists $opt{StdOut} && $opt{StdOut} ? 1 : 0;
    $self->{StdErr} =  exists $opt{StdErr} && $opt{StdErr} ? 1 : 0;
    $self->{Rewrite} = exists $opt{Rewrite} && $opt{Rewrite} ? 1 : 0;
    
    if( exists $opt{Rotate} ) {
	croak "Unknown rotate type '$opt{Rotate}'\n" unless exists $ROTATE_TYPES{$opt{Rotate}};
	$self->{Rotate} = $opt{Rotate};
    }
    else {
	$self->{Rotate} = $DEFAULT_ROTATE;
    }
    $self->{RotateTm} = undef;
    
    if( exists $opt{Level} ) {
        $self->level($opt{Level});
    }
    else {
        $self->{Level} = $DEFAULT_LEVEL;
    }
    
    $self->update_path;
    return undef unless $self->init_output($self->{Path});
    #$self->{Out}->autoflush(1);
    
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->close_output();
}

sub update_path {
    my ($self, $tm) = @_;
    
    $tm = time unless $tm;
    
    if( $self->{Rotate} eq 'const' ) {
	unless( $self->{Path} ) {
	    $self->{Path} = $self->{ConstPath};
	    return 1;
	}
    }
    else {
	if( !defined $self->{RotateTm} or $self->{RotateTm} <= $tm ) {
	    my $d = DateTime->from_epoch(epoch => $tm, time_zone => 'local');
	    if( $self->{Rotate} eq 'minutely' ) {
		$self->{Path} = $self->{ConstPath}.sprintf("-%.4d%.2d%.2d-%.2d%.2d", 
		    $d->year, $d->month, $d->day, $d->hour, $d->minute);
		$self->{RotateTm} = $d->add(minutes => 1)->truncate(to => 'minute')->epoch;
	    }
	    elsif( $self->{Rotate} eq 'hourly' ) {
		$self->{Path} = $self->{ConstPath}.sprintf("-%.4d%.2d%.2d-%.2d", 
		    $d->year, $d->month, $d->day, $d->hour);
		$self->{RotateTm} = $d->add(hours => 1)->truncate(to => 'hour')->epoch;
	    }
	    elsif( $self->{Rotate} eq 'daily' ) {
		$self->{Path} = $self->{ConstPath}.sprintf("-%.4d%.2d%.2d", 
		    $d->year, $d->month, $d->day);
		$self->{RotateTm} = $d->add(days => 1)->truncate(to => 'day')->epoch;
	    }
	    elsif( $self->{Rotate} eq 'monthly' ) {
		$self->{Path} = $self->{ConstPath}.sprintf("-%.4d%.2d", 
		    $d->year, $d->month);
		$self->{RotateTm} = $d->add(months => 1)->truncate(to => 'month')->epoch;
	    }
	    elsif( $self->{Rotate} eq 'yearly' ) {
		$self->{Path} = $self->{ConstPath}.sprintf("-%.4d", 
		    $d->year);
		$self->{RotateTm} = $d->add(years => 1)->truncate(to => 'year')->epoch;
	    }
	    else {
		croak "update_path(): unknown rotate type: '$self->{Rotate}'\n";
	    }
	    
	    return 1;
	}
    }
    
    return 0;
}

sub init_output {
    my ($self, $path, $mode) = @_;
    
    $mode = ( $self->{Rewrite} ? '>' : '>>' ) unless defined $mode;
    $self->close_output();
    return undef unless open($self->{Out}, $mode, $path);
    $self->{Path} = $path;
    $self->{IsOpen} = 1;
    $self->{Out}->autoflush(1);
    
    return 1;
}

sub close_output {
    my ($self) = @_;
    
    close($self->{Out}) if defined $self->{Out};
    $self->{Out} = undef;
    $self->{IsOpen} = undef;
}

sub change_output {
    my ($self) = @_;
    
    if( $self->update_path ) {
	$self->close_output;
	$self->init_output($self->{Path});
    }
}

sub is_open {
    my ($self) = @_;
    
    return $self->{IsOpen};
}

sub level {
    my ($self, $level) = @_;
    
    if( defined $level ) {
        if( exists $NAME_LEVEL_MAP{$level} ) {
            $self->{Level} = $NAME_LEVEL_MAP{$level};
        }
        else {
            croak "level(): Invalid level '$level'\n";
        }
    }
    
    return $LEVEL_NAME_MAP{$self->{Level}};
}

sub check_level {
    my ($self, $level) = @_;
    
    return $level >= $self->{Level};
}

sub write_message {
    my ($self, $level, @text) = @_;
    
    croak "write_msg(): Invalid level '$level'\n" unless exists $LEVEL_PREFIX{$level};
    
    return 1 unless $self->check_level($level);
    
    my $prefix = $LEVEL_PREFIX{$level}.
        (' ' x ($PREFIX_LENGTH - length($LEVEL_PREFIX{$level}))).
        "\t";
    
    $self->change_output;
    my $text = ($self->{DateTime} ? "[".scalar(localtime())."]\t" : "").
        join("", ($prefix, @text))."\n";
    print {$self->{Out}} $text;
    print STDOUT $text if $self->{StdOut};
    print STDERR $text if $self->{StdErr};
    
    return 1;
}

sub trace {
    my ($self, @text) = @_;
    return $self->write_message(LEVEL_TRACE, @text);
}

sub debug {
    my ($self, @text) = @_;
    return $self->write_message(LEVEL_DEBUG, @text);
}

sub info {
    my ($self, @text) = @_;
    return $self->write_message(LEVEL_INFO, @text);
}

sub warning {
    my ($self, @text) = @_;
    return $self->write_message(LEVEL_WARNING, @text);
}

sub error {
    my ($self, @text) = @_;
    return $self->write_message(LEVEL_ERROR, @text);
}

sub fatal {
    my ($self, @text) = @_;
    return $self->write_message(LEVEL_FATAL, @text);
}

sub log {
    my ($self, @text) = @_;
    return $self->write_message(LEVEL_NONE, @text);
}

1;
