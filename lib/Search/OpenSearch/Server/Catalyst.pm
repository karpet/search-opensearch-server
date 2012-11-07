package Search::OpenSearch::Server::Catalyst;

use warnings;
use strict;
use base qw( Search::OpenSearch::Server Catalyst::Controller );
use Carp;
use Data::Dump qw( dump );
use MRO::Compat;
use mro 'c3';

our $VERSION = '0.21_01';

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);
    $self->setup_engine();
    return $self;
}

sub setup_engine {
    my $self = shift;
    if ( defined $self->engine ) {
        return 1;
    }
    if ( defined $self->engine_config ) {
        $self->engine(
            Search::OpenSearch->engine(
                logger => $self,
                %{ $self->engine_config },
            )
        );
        return 1;
    }
    croak "engine() or engine_config() required";
}

sub log {
    my $self = shift;
    my $app  = $self->_app;
    my $msg  = shift or croak "No logger message supplied";
    my $lvl  = shift || 'debug';
    $req->log->$lvl($msg);
}

sub search : Local {
    my ( $self, $c ) = @_;
    my $request  = $c->request;
    my $response = $c->response;

    my $path = $request->path;
    if ( $request->method eq 'GET' and length $path == 1 ) {
        return $self->do_search( $request, $response );
    }
    elsif ( $request->method eq 'GET'
        and $self->engine->has_rest_api )
    {
        return $self->do_rest_api( $request, $response () );
    }
    if ( !$self->engine->has_rest_api && $request->method eq 'POST' ) {
        return $self->do_search( $request, $response );
    }
    elsif ( $self->engine->has_rest_api ) {
        return $self->do_rest_api( $request, $response );
    }
    else {
        return $self->handle_no_query( $request, $response );
    }
}

1;

__END__

=head1 NAME

Search::OpenSearch::Server::Catalyst - serve OpenSearch results with Catalyst

=head1 SYNOPSIS

 package MyApp::Controller::API;
 use strict;
 use warnings;
 use base 'Search::OpenSearch::Server::Catalyst';
 use MyStats;   # acts like a Dezi::Stats subclass
 
 __PACKAGE__->config(
    engine_config = {
        type   => 'Lucy',
        index  => ['path/to/your/index'],
        facets => {
            names       => [qw( topics people places orgs author )],
            sample_size => 10_000,
        },
        fields => [qw( topics people places orgs author )],
    },
    stats_logger => MyStats->new(),
 );

 1;

 # now you can:
 # GET  /api/search
 # POST /api/search
 
=head1 DESCRIPTION

Search::OpenSearch::Server::Catalyst is a L<Catalyst::Constroller> subclass.

=head1 METHODS

This class inherits from Search::OpenSearch::Server and Catalyst::Controller. Only
new or overridden methods are documented here.

=head2 new( I<params> )

Inherits from Plack::Component. I<params> can be:

=over

=item engine

A Search::OpenSearch::Engine instance. Either this or B<engine_config> is required.

=item engine_config

A hashref passed to the Search::OpenSearch->engine method.
Either this or B<engine> is required.

=item stats_logger

An object that implements at least one method called B<log>.
See L<Dezi::Stats> for example.

=back

=head2 search


=head2 log( I<msg>, I<level> )

Passes I<msg> on to the app $ctx->log method.

=head2 setup_engine

Instantiates the Search::OpenSearch::Engine, if necessary, using
the values set in engine_config().

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Server::Catalyst


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Search-OpenSearch-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Search-OpenSearch-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Search-OpenSearch-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/Search-OpenSearch-Server/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
