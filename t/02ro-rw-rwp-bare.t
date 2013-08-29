=pod

=encoding utf-8

=head1 PURPOSE

Test C<ro>, C<rw>, C<rwp> and C<bare> attributes.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

{
	package YYY;
	use Class::Tiny;
	sub ddd { 'inherited sub' };
}

{
	package XXX;
	use Class::Tiny;
	use Class::Tiny::Antlers;
	
	extends 'YYY';
	
	has aaa => (is => 'ro');
	has bbb => (is => 'rw');
	has ccc => (is => 'rwp');
	has ddd => (is => 'bare');
	has eee => ();  # default should be rw
}

my $obj = new_ok 'XXX' => [ aaa => 11, bbb => 12, ccc => 13, ddd => 14, eee => 15 ];

is($obj->aaa, 11, 'ro: reader');

$obj->aaa(21);
is($obj->aaa, 11, '... and cannot be used as writer');

is($obj->bbb, 12, 'rw: accessor (reading)');

$obj->bbb(22);
is($obj->bbb, 22, 'rw: accessor (writing)');

is($obj->ccc, 13, 'rwp: reader');

$obj->ccc(23);
is($obj->ccc, 13, '... and cannot be used as writer');

$obj->_set_ccc(23);
is($obj->ccc, 23, 'rwp: writer');

is($obj->{ddd}, 14, 'bare: internals');
is($obj->ddd, 'inherited sub', 'bare: no accessor generated');

is($obj->eee, 15, 'no is option: accessor (reading)');

$obj->eee(25);
is($obj->eee, 25, 'no is option: accessor (writing)');

done_testing;

