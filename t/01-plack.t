#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use Data::Dump qw( dump );
use JSON::XS;

SKIP: {

    my $index_path = $ENV{OPENSEARCH_INDEX};
    if ( !defined $index_path or !-d $index_path ) {
        diag("set OPENSEARCH_INDEX to valid path to test Plack with KSx");
        skip "set OPENSEARCH_INDEX to valid path to test Plack with KSx", 7;
    }
    eval "use Plack::Test";
    if ($@) {
        skip "Plack::Test not available", 7;
    }
    eval "use Search::OpenSearch::Engine::KSx";
    if ($@) {
        skip "Search::OpenSearch::Engine::KSx not available", 7;
    }

    require Search::OpenSearch::Server::Plack;
    require HTTP::Request;

    my $app = Search::OpenSearch::Server::Plack->new(
        engine_config => {
            type   => 'KSx',
            index  => [$index_path],
            facets => { names => [qw( topics people places orgs author )], },
            fields => [qw( topics people places orgs author )],
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new( GET => 'http://localhost/?q=test' );
            my $res = $cb->($req);
            ok( my $results = decode_json( $res->content ),
                "decode_json response" );
            is( $results->{query}, "test", "query param returned" );
            cmp_ok( $results->{total}, '>', 1, "more than one hit" );
            ok( exists $results->{search_time}, "search_time key exists" );
            is( $results->{title}, qq/OpenSearch Results/, "got title" );
        }
    );

    test_psgi(
        app    => $app,
        client => sub {
            my $cb  = shift;
            my $req = HTTP::Request->new( GET => 'http://localhost/' );
            my $res = $cb->($req);
            is( $res->content, qq/'q' required/, "missing 'q' param" );
            is( $res->code, 400, "bad request status" );
        }
    );

}
