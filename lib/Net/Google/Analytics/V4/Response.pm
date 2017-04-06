package Net::Google::Analytics::V4::Response;

use strict;
use warnings;

# ABSTRACT: Google Analytics Core Reporting API version 4 response

use Class::XSAccessor
    accessors => [ qw(
        is_success
        code message content
        column_headers
        reports
    ) ],
    constructor => 'new';

use Net::Google::Analytics::V4::Report;

sub error_message {
    my $self = shift;

    return join(' ', $self->code,  $self->message, $self->content);
}

sub _parse_json {
    my ($self, $json) = @_;
    my $reports = [];

    $self->column_headers( $json->{columnHeaders} );

    for my $raw_report (@{$json->{reports}}) {
        my $r = Net::Google::Analytics::V4::Report->new;
        $r->_parse_report( $raw_report );

        push @$reports, $r;
    }

    $self->reports( $reports );
}


1;
