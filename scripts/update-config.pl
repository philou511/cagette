#!/usr/bin/perl

use strict;
use v5.20;

# blow up if a variable is not set
use warnings FATAL => qw/uninitialized/;

use XML::Twig;
use utf8::all;

my $url = "mysql://$ENV{DB_USER}:$ENV{DB_USER_PW}\@$ENV{DB_HOST}/$ENV{DB_NAME}?useSSL=true&verifyServerCertificate=false";

my $twig = XML::Twig->new(
    pretty_print => 'nsgmls' # to pretty print attributes
);

$twig->parsefile( $ARGV[0] );

my $cagette_api = "https://$ENV{NEST_HOST_PUBLIC}";

my $cagette_bridge_api;
if ($ENV{KUBERNETES_PORT}) {
    say "Running in Kubernetes, using local address for Nest backend";
    $cagette_bridge_api = "http://$ENV{NEST_HOST_INTERNAL}:3010";
}
else {
    say "Running in Scalingo, using public address for Nest backend";
    $cagette_bridge_api = $cagette_api;
}

my $config = $twig->root;
$config->set_att(
    database           => $url,
    cagette_api        => $cagette_api,
    cagette_bridge_api => $cagette_bridge_api,
    host               => $ENV{NEKO_HOST_PUBLIC},
	key                => $ENV{PW_HASH_KEY},
);

$twig->print_to_file( $ARGV[1] ); # output the twig

