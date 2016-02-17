[![Build Status](https://travis-ci.org/powerman/perl-Log-Fast.svg?branch=master)](https://travis-ci.org/powerman/perl-Log-Fast)
[![Coverage Status](https://coveralls.io/repos/powerman/perl-Log-Fast/badge.svg?branch=master)](https://coveralls.io/r/powerman/perl-Log-Fast?branch=master)

# NAME

Log::Fast - Fast and flexible logger

# VERSION

This document describes Log::Fast version v1.0.6

# SYNOPSIS

    use Log::Fast;

    $LOG = Log::Fast->global();
    $LOG = Log::Fast->new({
        level           => 'WARN',
        prefix          => '%D %T [%L] ',
        type            => 'fh',
        fh              => \*STDOUT,
    });

    use Sys::Syslog qw( LOG_DAEMON );
    $LOG->config({
        prefix          => '',
        type            => 'unix',
        path            => '/dev/log',
        facility        => LOG_DAEMON,
        add_timestamp   => 1,
        add_hostname    => 1,
        hostname        => 'somehost',
        ident           => 'someapp',
        add_pid         => 1,
        pid             => $$,
    });

    $LOG->ident('anotherapp');
    $LOG->level('INFO');

    $LOG->ERR('Some error');
    $LOG->WARN('Some warning');
    $LOG->NOTICE('user %s logged in', $user);
    $LOG->INFO('data loaded');
    $LOG->DEBUG('user %s have %d things', $user, sub {
        return SlowOperation_GetAmountOfThingsFor($user);
    });

# DESCRIPTION

This is very fast logger, designed for use in applications with thousands
high-level events/operations per second (like network servers with
thousands clients or web spiders which download hundreds url per second).

For example, on Core2Duo sending about 5000 messages to log on enabled
log levels or 20000 messages on disabled log levels in _one second_ will
slow down your application only by 2-3%.

Comparing to some other CPAN modules, this one (in average):
faster than [Log::Dispatch](https://metacpan.org/pod/Log::Dispatch) in about 45 times,
faster than [Log::Handler](https://metacpan.org/pod/Log::Handler) in about 15 times,
faster than [Sys::Syslog](https://metacpan.org/pod/Sys::Syslog) in about 7 times,
and slower than [Log::Syslog::Fast](https://metacpan.org/pod/Log::Syslog::Fast) in about 2 times.

## FEATURES

- Global and local logger objects
- Output to any open filehandle or local syslog
- 5 log levels: ERR, WARN, NOTICE, INFO, DEBUG
- Configurable prefix (log level, date/time, caller function name)
- sprintf() support
- Unicode support (UTF8)
- Can avoid calculating log message content on disabled log levels

# INTERFACE 

- Log::Fast->global()

    When called first time will create global log object using
    [default options](#options) (you can reconfigure it using `config()` later).

    Global log object is useful if your application consists of several
    independent modules which should share same logging options configured
    outside of these modules. In this case all these modules should use
    same `global()` log object instead of creating `new()` independent log
    objects in each module.

    Return global log object.

- Log::Fast->new( \[\\%opt\] )

    Create new log object, configured using [defaults](#options) and
    user-provided options, if any.

    Return created log object.

- $LOG->config( \\%opt )

    Reconfigure log object. Any options (see ["OPTIONS"](#options)) can be changed at
    any time, including changing output **{type}** or setting options useless
    with current output type (new values for these options will be used later,
    if output type will be changed).

    If you need to change only log **{level}** or syslog's **{ident}** you should use
    `level()` or `ident()` methods because they are much faster than more general
    `config()`.

    Return nothing. Throw exception if unable to connect to syslog.

- $LOG->level( \[$level\] )

    If **$level** given will change current log level.
    This is same as call `config({ level=>$level })` but much faster.

    Return previous log level.

- $LOG->ident( \[$ident\] )

    If **$ident** given will change current syslog's ident.
    This is same as call `config({ ident=>$ident })` but much faster.

    Return previous syslog's ident.

- $LOG->ERR( $message )
- $LOG->ERR( $format, @list )
- $LOG->WARN( $message )
- $LOG->WARN( $format, @list )
- $LOG->NOTICE( $message )
- $LOG->NOTICE( $format, @list )
- $LOG->INFO( $message )
- $LOG->INFO( $format, @list )
- $LOG->DEBUG( $message )
- $LOG->DEBUG( $format, @list )

    Output **$message** to log using different log levels.

    If **$format, @list** used instead of **$message**, then use
    `sprintf($format, @list)` to calculate log message.

    If **@list** will contain CODEREF, they will be called (in LIST context)
    and returned values will be placed inside **@list** inplace of CODEREF.
    This can be used to avoid calculating log message (or it part) on disabled
    log levels - these CODEREFs will be executed only on enabled log levels.
    Example available in ["SYNOPSIS"](#synopsis).

    If **$message** or items in **@list** will be Unicode strings, they will be
    converted to UTF8 before sending to log.

    Return nothing. Throw exception if fail to write message to log.

# OPTIONS

Defaults for all options are:

    level           => 'DEBUG',
    prefix          => q{},

    type            => 'fh',
    fh              => \*STDERR,

    # these will be used if you will call config({ type=>'unix' })
    path            => Sys::Syslog::_PATH_LOG() || '/dev/log',
    facility        => LOG_USER,
    add_timestamp   => 1,
    add_hostname    => 0,
    hostname        => Sys::Hostname::hostname(),
    ident           => ..., # calculated from $0
    add_pid         => 1,
    pid             => $$,

- level

    Current log level. Possible values are:
    `'ERR'`, `'WARN'`, `'NOTICE'`, `'INFO'`, `'DEBUG'`.

    Only messages on current or higher levels will be sent to log.

- prefix

    String, which will be output at beginning of each log message.
    May contain these placeholders:

        %L - log level of current message
        %S - hi-resolution time (seconds.microseconds)
        %D - current date in format YYYY-MM-DD
        %T - current time in format HH:MM:SS
        %P - caller's function package ('main' or 'My::Module')
        %F - caller's function name
        %_ - X spaces, where X is current stack depth
        %% - % character

    Example output with prefix `'%D %T [%L]%_%P::%F() '`:

        2010-11-17 18:06:20 [INFO] main::() something from main script
        2010-11-17 18:06:53 [INFO]  main::a() something from a
        2010-11-17 18:09:09 [INFO]   main::b2() something from b1->b2
        2010-11-17 18:06:56 [INFO]  main::c() something from c

    If it will be Unicode string, it will be converted to UTF8.

- type

    Output type. Possible values are: `'fh'` (output to any already open
    filehandle) and `'unix'` (output to syslog using UNIX socket).

    When **{type}** set to `'fh'` you have to also set **{fh}** to any open
    filehandle (like `\*STDERR`).

    When **{type}** set to `'unix'` you have to also set **{path}** to path to
    existing unix socket (typically it's `'/dev/log'`).

    Luckily, default values for both **{fh}** and **{path}** are already provided,
    so usually it's enough to just set **{type}**.

- fh

    File handle to write log messages if **{type}** set to `'fh'`.

- path

    Syslog's UNIX socket path to write log messages if **{type}** set to `'unix'`.

- facility

    Syslog's facility (see ["Facilities" in Sys::Syslog](https://metacpan.org/pod/Sys::Syslog#Facilities) for a list of well-known facilities).

    This module doesn't export any constants, so if you wanna change it from default
    LOG\_USER value, you should import facility constants from [Sys::Syslog](https://metacpan.org/pod/Sys::Syslog) module.
    Example available in ["SYNOPSIS"](#synopsis).

- add\_timestamp

    If TRUE will include timestamp in syslog messages.

- add\_hostname

    If TRUE will include hostname in syslog messages.

- hostname

    Host name which will be included in syslog messages if **{add\_hostname}** is TRUE.

- ident

    Syslog's ident (application name) field.

    If it will be Unicode string, it will be converted to UTF8.
    Using non-ASCII ALPHANUMERIC ident isn't allowed by RFC, but usually
    works.

- add\_pid

    If TRUE will include PID in syslog messages.

- pid

    PID which will be included in syslog messages if **{add\_pid}** is TRUE.

# SPEED HINTS

Empty prefix is fastest. Prefixes `%L`, `%P` and `%%` are fast enough,
`%D` and `%T` has average speed, `%S`, `%F` and `%_` are slowest.

Output to file is about 4 times faster than to syslog.

Calling log with single parameter is faster than with many parameters
(because in second case sprintf() have to be used).

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/powerman/perl-Log-Fast/issues](https://github.com/powerman/perl-Log-Fast/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

[https://github.com/powerman/perl-Log-Fast](https://github.com/powerman/perl-Log-Fast)

    git clone https://github.com/powerman/perl-Log-Fast.git

## Resources

- MetaCPAN Search

    [https://metacpan.org/search?q=Log-Fast](https://metacpan.org/search?q=Log-Fast)

- CPAN Ratings

    [http://cpanratings.perl.org/dist/Log-Fast](http://cpanratings.perl.org/dist/Log-Fast)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Log-Fast](http://annocpan.org/dist/Log-Fast)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Log-Fast](http://matrix.cpantesters.org/?dist=Log-Fast)

- CPANTS: A CPAN Testing Service (Kwalitee)

    [http://cpants.cpanauthors.org/dist/Log-Fast](http://cpants.cpanauthors.org/dist/Log-Fast)

# AUTHOR

Alex Efros &lt;powerman@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2010-2012 by Alex Efros &lt;powerman@cpan.org>.

This is free software, licensed under:

    The MIT (X11) License
