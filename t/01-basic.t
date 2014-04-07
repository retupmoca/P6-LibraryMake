use v6;
use Test;

use LibraryMake;

ok True, "Can load module";

my %vars = get-vars('.');
ok %vars<CC>:exists, "Can get vars";

process-makefile('t', %vars);
ok True, "Process makefile didn't die";
ok ("t/Makefile".IO ~~ :f), "Makefile was created";

shell(%vars<MAKE> ~ " -C t");
ok (("t/test"~%vars<O>).IO ~~ :f), "Object file created";
ok ("t/test".IO ~~ :f), "Binary was created";

ok qx/t\/test/ eq "Hello world!\n", "Binary runs!";
