use inc::Module::Install;

name     'Log-Fast';
all_from 'lib/Log/Fast.pm';

requires        'version';
requires        'Sys::Syslog'           => '0.29';

test_requires   'Test::More';
test_requires   'Test::Exception';

recommends      'Test::CheckManifest'   => '0.9';
recommends      'Test::Perl::Critic';
recommends      'Test::Pod::Coverage'   => '1.08';
recommends      'Pod::Coverage'         => '0.18';
recommends      'Test::Pod'             => '1.22';

auto_install;

WriteAll;

