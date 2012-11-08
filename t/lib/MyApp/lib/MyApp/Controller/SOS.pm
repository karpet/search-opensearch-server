package MyApp::Controller::SOS;
use strict;
use base qw( CatalystX::Controller::OpenSearch );

__PACKAGE__->config(
    engine_config => {
        type  => 'Lucy',
        index => [ $ENV{OPENSEARCH_INDEX} ],
    },
    stats_logger => MyStats->new(),            # in t/03
    http_allow   => [qw( GET PUT DELETE )],    # no POST
);

1;
