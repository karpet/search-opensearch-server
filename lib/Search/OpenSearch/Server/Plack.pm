package Search::OpenSearch::Server::Plack;

use warnings;
use strict;
use base qw( Plack::Middleware );
use Carp;
use Search::OpenSearch;
use Plack::Request;
use Plack::Util::Accessor qw( engine engine_config );

our $VERSION = '0.02';

my %formats = (
    'XML'  => 'application/xml',
    'JSON' => 'application/json',
);

sub prepare_app {
    my $self = shift;
    $self->setup_engine();
}

sub setup_engine {
    my $self = shift;
    if ( defined $self->engine ) {
        return 1;
    }
    if ( defined $self->engine_config ) {

        # this appears to correctly defer creation
        # till each child is created, regardless of -L Delayed
        # So nice when code Just Works.
        #warn "[$$] engine created";

        $self->engine(
            Search::OpenSearch->engine( %{ $self->engine_config } ) );
        return 1;
    }
    croak "engine() or engine_config() required";
}

sub call {
    my ( $self, $env ) = @_;
    my $req = Plack::Request->new($env);
    return $self->do_search($req);
}

sub handle_no_query {
    my ( $self, $response ) = @_;
    $response->status(400);
    $response->content_type('text/plain');
    $response->body("'q' required");
    return $response;
}

sub do_search {
    my ( $self, $req ) = @_;
    my %args     = ();
    my $params   = $req->parameters;
    my $response = $req->new_response;
    my $query    = $params->{q};
    if ( !defined $query ) {
        $response = $self->handle_no_query($response);
    }
    else {
        for my $param (qw( q s o p h c L f format )) {
            $args{$param} = $params->{$param};
        }

        # map some Ext param names to Engine API
        if ( defined $params->{start} ) {
            $args{'o'} = $params->{start};
        }
        if ( defined $params->{limit} ) {
            $args{'p'} = $params->{limit};
        }

        $args{format} = uc( $args{format} || 'JSON' );
        if ( !exists $formats{ $args{format} } ) {

            # TODO better way to log?
            warn "bad format $args{format} -- using JSON\n";
            $args{format} = 'JSON';
        }

        my $search_response = $self->engine->search(%args);

        if ( !$search_response ) {
            $response->status(500);
            $response->content_type('text/plain');
            $response->body("Internal error");
        }
        else {
            $search_response->debug(1) if $params->{debug};
            $response->status(200);
            $response->content_type( $formats{ $args{format} } );
            $response->body("$search_response");
        }

    }

    return $response->finalize();
}

1;

__END__

=head1 NAME

Search::OpenSearch::Server::Plack - serve OpenSearch results with Plack

=head1 SYNOPSIS

 # write a PSGI application in yourapp.psgi
 use strict;
 use warnings;
 use Plack::Builder;
 use Search::OpenSearch::Server::Plack;
 
 my $engine_config = {
    type   => 'KSx',
    index  => ['path/to/your/index'],
    facets => {
        names       => [qw( topics people places orgs author )],
        sample_size => 10_000,
    },
    fields => [qw( topics people places orgs author )],
 };

 my $app = Search::OpenSearch::Server::Plack->new( 
    engine_config => $engine_config
 );

 builder {
    mount '/' => $app;
 };

 
 # run the app
 % plackup yourapp.psgi
 
=head1 DESCRIPTION

Search::OpenSearch::Server::Plack is a L<Plack::Middleware> application.
This module implements a HTTP-ready L<Search::OpenSearch> server using L<Plack>.

=head1 METHODS

=head2 call

Implements the required Middleware method. The default behavior is to
instantiate a L<Plack::Request> and pass it into do_search().

=head2 prepare_app

Calls setup_engine().

=head2 setup_engine

Instantiates the Search::OpenSearch::Engine, if necessary, using
the values set in engine_config().

=head2 do_search( I<request> )

The meat of the application. This method checks params in I<request>,
mapping them to the Search::OpenSearch::Engine API.

Returns a Plack::Reponse, finalize()d.

=head2 handle_no_query( I<response> )

If no 'q' param is present in the Plack::Request, this method is called.
The default behavior is to set a 400 (bad request) with error message.
You can override it to behave more kindly.
 
=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-search-opensearch-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Search-OpenSearch-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Search::OpenSearch::Server


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

Copyright 2010 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
