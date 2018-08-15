module LibraryMake
------------------

An attempt to simplify building native code for a perl6 module.

This is effectively a small configure script for a Makefile. It will allow you to use the same tools to build your native code that were used to build perl6 itself.

Typically, this will be used in both Build.pm (to support installation using a module manager), and in a standalone Configure.pl script in the src directory (to support standalone testing/building). Note that if you need additional custom configure code, you will currently need to add it to both your Build.pm and to your Configure.pl6

Example Usage
-------------

The below files are examples of what you would write in your own project. The src directory is merely a convention, and the Makefile.in will likely be significantly different in your own project.

/Build.pm

    use v6;
    use LibraryMake;
    use Shell::Command;

    my $libname = 'chelper';

    class Build {
        method build($dir) {
            my %vars = get-vars($dir);
            %vars{$libname} = $*VM.platform-library-name($libname.IO);
            mkdir "$dir/resources" unless "$dir/resources".IO.e;
            mkdir "$dir/resources/libraries" unless "$dir/resources/libraries".IO.e;
            process-makefile($dir, %vars);
            my $goback = $*CWD;
            chdir($dir);
            shell(%vars<MAKE>);
            chdir($goback);
        }
    }

/src/Configure.pl6

    #!/usr/bin/env perl6
    use v6;
    use LibraryMake;

    my $libname = 'chelper';
    my %vars = get-vars('.');
    %vars{$libname} = $*VM.platform-library-name($libname.IO);
    mkdir "resources" unless "resources".IO.e;
    mkdir "resources/libraries" unless "resources/libraries".IO.e;
    process-makefile('.', %vars);
    shell(%vars<MAKE>);

    say "Configure completed! You can now run '%vars<MAKE>' to build lib$libname.";

/src/Makefile.in (Make sure you use TABs and not spaces!)

    .PHONY: clean test

    all: %DESTDIR%/resources/libraries/%chelper%

    clean:
        -rm %DESTDIR%/resources/libraries/%chelper% %DESTDIR%/*.o

    %DESTDIR%/resources/libraries/%chelper%: chelper%O%
        %LD% %LDSHARED% %LDFLAGS% %LIBS% %LDOUT%%DESTDIR%/resources/libraries/%chelper% chelper%O%

    chelper%O%: src/chelper.c
        %CC% -c %CCSHARED% %CCFLAGS% %CCOUT% chelper%O% src/chelper.c

    test: all
        prove -e "perl6 -Ilib" t

/lib/My/Module.pm6

    # ...

    use NativeCall;
    use LibraryMake;

    constant CHELPER = %?RESOURCES<libraries/chelper>.absolute;

    sub foo() is native( CHELPER ) { * };

/META6.json

    # include the following section in your META6.json:
    "resources" : [
        "library/chelper"
    ],
    "depends" : [
        "LibraryMake"
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
