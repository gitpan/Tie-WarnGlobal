package Tie::WarnGlobal::Scalar;

use strict;
use vars qw(%FIELDS);

use Carp;


# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

use fields qw(get set name warn die_on_write);

################################# Methods ###############################

sub TIESCALAR {
    my $type = shift;
    my ($in) = @_;

    exists $in->{'get'} or croak "Improper use of 'tie' on $type: Field 'get' required; stopped";

    no strict 'refs';
    my Tie::WarnGlobal::Scalar $self = bless [ \%{"${type}::FIELDS"} ], $type;
    $self->{'get'} = $in->{'get'};
    $self->{'set'} = $in->{'set'} if defined $in->{'set'};
    $self->{'name'} = $in->{'name'} if defined $in->{'name'};
    $self->{'die_on_write'} = $type->_get_boolean($in, 'die_on_write', 0);
    $self->{'warn'} = $type->_get_boolean($in, 'warn', 1);

    return $self;
}

sub _get_boolean {
    my $type = shift;
    my ($hash, $member, $default) = @_;

    if ( defined $hash->{$member} ) {
	return $hash->{$member};
    }
    else {
	return $default;
    }
}

sub FETCH {
    my Tie::WarnGlobal::Scalar $self = shift;
    
    $self->{'warn'} and do {
	warn(ucfirst($self->_get_identifier()), " was read-accessed ", $self->_get_caller_info());
    };

    return $self->{'get'}->();
}

sub _get_caller_info {
    my Tie::WarnGlobal::Scalar $self = shift;

    my ($package, $filename, $line, $subroutine) = caller(1);
    return "at $filename line $line.\n";
}



sub _get_identifier {
    my Tie::WarnGlobal::Scalar $self = shift;

    if (defined $self->{'name'}) {
	return "global '$self->{'name'}'";
    }
    else {
	return "a global";
    }
}

sub STORE {
    my Tie::WarnGlobal::Scalar $self = shift;
    my ($new_value) = @_;

    if ( $self->{'warn'} && (! $self->{'die_on_write'} ) ) {
	warn(ucfirst( $self->_get_identifier() ), " was write-accessed ", $self->_get_caller_info());
    }

    if (! defined($self->{'set'}) ) {

	if ( defined($self->{'die_on_write'}) && $self->{'die_on_write'} ) {
	    die "Attempt to write-access ", $self->_get_identifier(), "(read-only) ", $self->_get_caller_info();
	}
    }
    else {
	$self->{'set'}->($new_value);
    }
}

sub DESTROY { }

sub warn {
    my Tie::WarnGlobal::Scalar $self = shift;
    my ($warn_val) = @_;

    $self->{'warn'} = $warn_val;
}

sub die_on_write {
    my Tie::WarnGlobal::Scalar $self = shift;
    my ($die_val) = @_;

    $self->{'die_on_write'} = $die_val;
}

1;
__END__

=head1 NAME

Tie::WarnGlobal::Scalar - Perl extension aiding elimination of globals

=head1 SYNOPSIS

  use Tie::WarnGlobal::Scalar;

  tie $MY_READONLY, 'Tie::WarnGlobal::Scalar', { name => '$MY_READONLY', get => \&get_function, die_on_write => 1 };
  tie $MY_GLOBAL, 'Tie::WarnGlobal::Scalar', { get => \&get_function, set => \&set_function, warn => 0 };

  my $tied = tied $MY_GLOBAL;
  $tied->warn(1);
  ## ...
  $tied->warn(0);

  $tied->die_on_write(1);
  ## ...
  $tied->die_on_write(0);

=head1 DESCRIPTION

Globals are elusive things. If you inherit (or write) a program with
all kinds of global package variables, it can be hard to find them,
and time-consuming to replace them all at once.

Tie::WarnGlobal::Scalar is a partial answer. Once you've written a
routine that returns the value that was originally in your global
variable, you can tie that variable to the function, and the variable
will always return the value of the function. This can be valuable
while testing, since it serves to verify that you've written your new
'get'-function correctly.

In order to trace down uses of the given global,
Tie::WarnGlobal::Scalar can provide warnings whenever the global is
accessed. These warnings are on by default; they are controlled by the
'warn' parameter. Also, one can turn warnings on and off with the
warn() method on the tied object. If 'die_on_write' is set,
Tie::WarnGlobal::Scalar will die if an attempt is made to write to a
value with no 'set' method defined. (Otherwise, the 'set' method will
produce a warning, but will have no affect on the value.)

=head1 AUTHOR

Stephen Nelson, steven@jubal.com

=head1 SEE ALSO

perl(1).

=cut


