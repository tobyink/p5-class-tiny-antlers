use strict;
use warnings;
use Test::More;
use Test::Requires 'Type::Nano';
use Test::Fatal;

{
	package Local::Foo;
	use Type::Nano 'Int';
	use Class::Tiny::Antlers;
	has foo => (is => 'rw', isa => Int);
};

my $o1 = Local::Foo->new(foo => 42);
is($o1->foo, 42);
$o1->foo(43);
is($o1->foo, 43);

my $e = exception { $o1->foo('bar') };
like($e, qr/type constraint/);

my $e2 = exception { Local::Foo->new(foo => 'baz') };
like($e2, qr/type constraint/);

done_testing;
