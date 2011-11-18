use inc::Module::Install;
use Module::Install::AuthorTests;

name 'Acme-Shiin';
all_from 'lib/Acme/Shiin.pm';

#requires '';

test_requires 'Test::More', 0.98;

tests join q{ }, map { sprintf 't%s.t', '/*' x $_ } 1..3;
author_tests 'xt';

repository 'http://github.com/xaicron/p5-Acme-Shiin/';
bugtracker 'http://github.com/xaicron/p5-Acme-Shiin/issues';

WriteAll;
