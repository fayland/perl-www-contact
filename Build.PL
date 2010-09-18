use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Contact',
    license             => 'perl',
    dist_author         => 'Fayland Lam <fayland@gmail.com>',
    dist_version_from   => 'lib/WWW/Contact.pm',
    build_requires => {
        'Test::More' => '0.90',
    },
    requires => {
        'Moose' => '0.77',
        'WWW::Mechanize' => 0,
        'WWW::Mechanize::GZip' => 0,
        'HTML::TreeBuilder'    => 0,
        'HTML::TokeParser::Simple' => 0,
        'Crypt::SSLeay' => 0, # https
        'Net::Google::AuthSub' => 0,
        'JSON::XS' => 0,
        'Text::vCard' => 0,
        'HTML::Entities' => 0,
        'Net::DNS::Resolver' => 0,
    },
    add_to_cleanup      => [ 'WWW-Contact-*' ],
    create_makefile_pl => 'traditional',
    meta_merge     => {
        resources => {
            repository => 'http://github.com/fayland/perl-www-contact/tree/master',
        }
    },
);

$builder->create_build_script();
