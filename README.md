P6-LibraryMake
==============

An attempt to simplify building native code for a perl6 module.

This is effectively a small configure script for a Makefile. It will allow you to
use the same tools to build your native code that were used to build perl6 itself.

Typically, this will be used in both Build.pm (to support panda installs), and in
a standalone Configure.pl script in the src directory (to support standalone
testing/building). Note that if you need additional custom configure code, you
will currently need to add it to both your Build.pm and to your Configure.pl6

## Example Usage ##

The below files are examples of what you would write in your own project.
The src directory is merely a convention, and the Makefile.in will likely be significantly
different in your own project.

/Build.pm

    use Panda::Common;
    use Panda::Builder;
    use LibraryMake;
    use Shell::Command;
    
    class Build is Panda::Builder {
        method build($workdir) {
            mkpath "$workdir/blib/lib";
            make("$workdir/src", "$workdir/blib/lib");
        }
    }

/src/Configure.pl6

    # Note that this is *not* run during panda install
    # The example here is what the 'make' call in Build.pm does
    use LibraryMake;
    
    my $destdir = '../lib';
    my %vars = get-vars($destdir);
    process-makefile('.', %vars);

/src/Makefile.in

    all: %DESTDIR%/libfoo%SO%

    %DESTDIR%/libfoo%SO%: libfoo%O%
        %LD% %LDSHARED% %LDFLAGS% %LIBS% %LDUSR%pam %LDOUT%%DESTDIR%/libfoo%SO% libfoo%O%

    libfoo%O%: libfoo.c
        %CC% -c %CCSHARED% %CCFLAGS% %CCOUT%libfoo%O% libfoo.c

/lib/Foo.pm6

    # ...

    use NativeCall;
    use LibraryMake;

    # Find our compiled library.
    # It was installed along with this .pm6 file, so it should be somewhere in
    # @*INC
    sub library {
        my $so = get-vars('')<SO>;
        for @*INC {
            if ($_~'/libfoo'~$so).IO ~~ :f {
                return $_~'/libfoo'~$so;
            }
        }
        die "Unable to find library";
    }

    # we do this instead of 'is native(...)' because 'is native' will resolve the
    # library at compile time, while we need it to happen at runtime (because
    # this library is installed *after* being compiled).
    #
    # This is a bit of a hack, will hopefully change soon with a NativeCall update.
    sub foo() { * };
    trait_mod:<is>(&foo, :native(library));

## Functions ##

 -  `get-vars($destdir)`

 -  `process-makefile($folder, %vars)`

 -  `make($folder, $destfolder)`
