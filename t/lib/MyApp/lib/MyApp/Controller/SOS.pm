package MyApp::Controller::SOS;
use base qw( Search::OpenSearch::Server::Catalyst );

__PACKAGE__->config(
    engine_config => {
        type  => 'Lucy',
        index => [$index_path],
    },
    stats_logger => MyStats->new(),            # in t/03
    http_allow   => [qw( GET PUT DELETE )],    # no POST
);

1;
