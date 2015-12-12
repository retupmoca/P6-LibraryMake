module LibraryMake
------------------

An attempt to simplify building native code for a perl6 module.

This is effectively a small configure script for a Makefile. It will allow you to use the same tools to build your native code that were used to build perl6 itself.

Typically, this will be used in both Build.pm (to support panda installs), and in a standalone Configure.pl script in the src directory (to support standalone testing/building). Note that if you need additional custom configure code, you will currently need to add it to both your Build.pm and to your Configure.pl6

Example Usage
-------------

The below files are examples of what you would write in your own project. The src directory is merely a convention, and the Makefile.in will likely be significantly different in your own project.

/Build.pm

    use Panda::Common;
    use Panda::Builder;
    use LibraryMake;
    use Shell::Command;

    class Build is Panda::Builder {
        method build($workdir) {
            my $makefiledir = "$workdir/src";
            my $destdir = "$workdir/resources";
            mkpath $destdir;
            make($makefiledir, $destdir);
        }
    }

/src/Configure.pl6

    # Note that this is *not* run during panda install - it is intended to be
    # run manually for testing / recompiling without needing to do a 'panda install'
    #
    # The example here is how the 'make' sub generates the makefile in the above Build.pm file
    use LibraryMake;

    my $destdir = '../resources';
    my %vars = get-vars($destdir);
    process-makefile('.', %vars);

    say "Configure completed! You can now run '%vars<MAKE>' to build libfoo.";

/src/Makefile.in

    all: %DESTDIR%/libfoo%SO%

    %DESTDIR%/libfoo%SO%: libfoo%O%
        %LD% %LDSHARED% %LDFLAGS% %LIBS% %LDUSR%pam %LDOUT%%DESTDIR%/libfoo%SO% libfoo%O%

    libfoo%O%: libfoo.c
        %CC% -c %CCSHARED% %CCFLAGS% %CCOUT%libfoo%O% libfoo.c

/lib/My/Module.pm6

    # ...

    use NativeCall;
    use LibraryMake;

    # Find our compiled library.
    sub library {
        my $so = get-vars('')<SO>;
        return ~(%?RESOURCES{"libfoo$so"});
    }

    # we put 'is native(&library)' because it will call the function and resolve the
    # library at compile time, while we need it to happen at runtime (because
    # this library is installed *after* being compiled).
    sub foo() is native(&library) { * };

/META.info

    # include the following section in your META.info:
    "resources" : [
        "libfoo.so"
    ]

Functions
---------

### sub get-vars

```
sub get-vars(
    Str $destfolder
) returns Hash
```

Returns configuration variables. Effectively just a wrapper around $*VM.config, as the VM config variables are different for each backend VM.

### sub process-makefile

```
sub process-makefile(
    Str $folder,
    %vars
) returns Mu
```

Takes '$folder/Makefile.in' and writes out '$folder/Makefile'. %vars should be the result of get-vars above.

### sub make

```
sub make(
    Str $folder,
    Str $destfolder
) returns Mu
```

Calls get-vars and process-makefile for you to generate '$folder/Makefile', then runs your system's 'make' to build it.
