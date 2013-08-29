use strict;
use warnings;

package Class::Tiny::Antlers;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.019';

use Class::Tiny 0.005 ();

sub import
{
	shift;
	my $caller = caller;
	no strict 'refs';
	*{"$caller\::has"}     = sub { unshift @_, $caller; goto \&has };
	*{"$caller\::extends"} = sub { unshift @_, $caller; goto \&extends };
	*{"$caller\::with"}    = sub { unshift @_, $caller; goto \&with };
}

sub croak
{
	require Carp;
	my ($fmt, @values) = @_;
	Carp::croak(sprintf($fmt, @values));
}

sub has
{
	my $caller = shift;
	my ($attr, %spec) = @_;

	if (defined($attr) and ref($attr) eq q(ARRAY))
	{
		has($caller, $_, %spec) for @$attr;
		return;
	}

	if (!defined($attr) or ref($attr) or $attr !~ /^[^\W\d]\w*$/s)
	{
		croak("Invalid accessor name '%s'", $attr);
	}
	
	my $init_arg  = exists($spec{init_arg}) ? delete($spec{init_arg}) : \undef;
	my $is        = delete($spec{is}) || 'rw';
	my $required  = delete($spec{required});
	my $default   = delete($spec{default});
	my $lazy      = delete($spec{lazy});
	my $clearer   = delete($spec{clearer});
	my $predicate = delete($spec{predicate});
	
	if ($is eq 'lazy')
	{
		$lazy = 1;
		$is   = 'ro';
	}
	
	if (defined $lazy and not $lazy)
	{
		croak("Class::Tiny does not support eager defaults");
	}
	elsif ($spec{isa} or $spec{coerce})
	{
		croak("Class::Tiny does not support type constraints");
	}
	elsif (keys %spec)
	{
		croak("Unknown options in attribute specification (%s)", join ", ", sort keys %spec);
	}
	
	if ($required and 'Class::Tiny::Object'->can('new') == $caller->can('new'))
	{
		croak("Class::Tiny::Object::new does not support required attributes; please manually override the constructor to enforce required attributes");
	}
	
	if ($init_arg and ref($init_arg) eq 'SCALAR' and not defined $$init_arg)
	{
		# ok
	}
	elsif (!$init_arg or $init_arg ne $attr)
	{
		croak("Class::Tiny does not support init_arg");
	}
	
	my $getter = "\$_[0]{'$attr'}";
	if (defined $default and ref($default) eq 'CODE')
	{
		$getter = "\$_[0]{'$attr'} = \$default->(\$_[0]) unless exists \$_[0]{'$attr'}; $getter";
	}
	elsif (defined $default)
	{
		$getter = "\$_[0]{'$attr'} = \$default unless exists \$_[0]{'$attr'}; $getter";
	}
	
	my @methods;
	if ($is eq 'rw')
	{
		push @methods, "sub $attr :method { \$_[0]{'$attr'} = \$_[1] if \@_ > 1; $getter };";
	}
	elsif ($is eq 'ro' or $is eq 'rwp')
	{
		push @methods, "sub $attr :method { $getter };";
		push @methods, "sub _set_$attr :method { \$_[0]{'$attr'} = \$_[1] };"
			if $is eq 'rwp';
	}
	elsif ($is ne 'bare')
	{
		croak("Class::Tiny::Antlers does not support '$is' accessors");
	}
	
	if ($clearer)
	{
		$clearer = ($attr =~ /^_/) ? "_clear$attr" : "clear_$attr" if $clearer eq '1';
		push @methods, "sub $clearer :method { delete(\$_[0]{'$attr'}) }";
	}
	
	if ($predicate)
	{
		$predicate = ($attr =~ /^_/) ? "_has$attr" : "has_$attr" if $predicate eq '1';
		push @methods, "sub $predicate :method { exists(\$_[0]{'$attr'}) }";
	}
	
	eval "package $caller; @methods use Class::Tiny qw($attr);";
}

sub extends
{
	my $caller = shift;
	my (@parents) = @_;
	
	for my $parent (@parents)
	{
		eval "require $parent";
	}
	
	no strict 'refs';
	@{"$caller\::ISA"} = @parents;
}

sub with
{
	my $caller = shift;
	require Role::Tiny::With;
	goto \&Role::Tiny::With::with;
}

1;


__END__

=pod

=encoding utf-8

=head1 NAME

Class::Tiny::Antlers - Moose-like sugar for Class::Tiny

=head1 SYNOPSIS

   {
      package Point;
      use Class::Tiny;
      use Class::Tiny::Antlers;
      has x => (is => 'ro');
      has y => (is => 'ro');
   }
   
   {
      package Point3D;
      use Class::Tiny;
      use Class::Tiny::Antlers;
      extends 'Point';
      has z => (is => 'ro');
   }

=head1 DESCRIPTION

Class::Tiny::Antlers provides L<Moose>-like C<has>, C<extends> and C<with>
keywords for L<Class::Tiny>. (The C<with> keyword requires L<Role::Tiny>.)

Class::Tiny doesn't support all Moose's attribute options; C<has> should
throw you an error if you try to do something it doesn't support (like
triggers or type constraints).

Class::Tiny::Antlers does however hack in support for C<< is => 'ro' >>
and Moo-style C<< is => 'rwp' >>, clearers and predicates.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Class-Tiny-Antlers>.

=head1 SEE ALSO

L<Class::Tiny>, L<Moose>, L<Moo>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
