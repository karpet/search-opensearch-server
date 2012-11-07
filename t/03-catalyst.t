#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib/MyApp/lib';
use Test::More tests => 19;
use Data::Dump qw( dump );
use JSON;

{

    package MyStats;

    sub new {
        return bless {}, shift;
    }

    sub log {
        my ( $self, $req, $resp ) = @_;
        Test::More::ok( ref $resp, "response is a ref" );

        #Test::More::diag( Data::Dump::dump $resp );

    }

}

SKIP: {

    my $index_path = $ENV{OPENSEARCH_INDEX};
    if ( !defined $index_path or !-d $index_path ) {
        diag("set OPENSEARCH_INDEX to valid path to test Plack with Lucy");
        skip "set OPENSEARCH_INDEX to valid path to test Plack with Lucy", 19;
    }
    eval "use Catalyst::Test qw(MyApp)";
    if ($@) {
        warn $@;
        skip "Catalyst::Test not available", 19;
    }
    eval "use HTTP::Request::Common";
    if ($@) {
        warn $@;
        skip "HTTP::Request::Common not available", 19;
    }
    eval "use Search::OpenSearch::Engine::Lucy";
    if ($@) {
        skip "Search::OpenSearch::Engine::Lucy not available", 19;
    }

    my $res;
    ok( $res = request( GET('/sos/search?q=test') ),
        "GET /sos/search?q=test" );
    dump $res;

}
