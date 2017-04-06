package Net::Google::Analytics::V4;

use strict;
use warnings;

# ABSTRACT: Simple interface to the Google Analytics Core Reporting API version 4
#
# Enable it by visiting https://console.developers.google.com/apis/api/analyticsreporting.googleapis.com/overview
#

use URI;
use JSON;
use LWP::UserAgent;

use Net::Google::Analytics::V4::Request;
use Net::Google::Analytics::V4::Response;

my $_ENDPOINT = 'https://analyticsreporting.googleapis.com/v4/reports:batchGet';


sub new {
    my $package = shift;
    return bless({}, $package);
}

sub token {
    my ($self, $token) = @_;

    $self->{auth_params} = [
        Authorization => "$token->{token_type} $token->{access_token}",
    ];
}

sub user_agent {
    my $self = shift;

    unless ( $self->{user_agent} ) { $self->{user_agent} = LWP::UserAgent->new() }

    return $self->{user_agent};
}

sub uri {
    my ($self, $req, @params) = @_;

    my $uri = URI->new( $_ENDPOINT );

    $uri->query_form(
        $req->params,
        @params,
    );

    return $uri;
}

sub retrieve {
    my ($self, $req) = @_;
    my $res = {};

    return unless $req;

    my $json = JSON->new;
    my $json_req = $json->utf8->encode( $req->report_request );

    my %headers = @{$self->{auth_params}};
    $headers{'Content-Type'} = 'application/json';

    my $uri = $self->uri( $req );

    my $post = HTTP::Request->new( 'POST', $uri->as_string );
    $post->header( %headers );
    $post->content( $json_req );

    my $http_res = $self->user_agent->request( $post );

    $res = Net::Google::Analytics::V4::Response->new;
    $res->code($http_res->code);
    $res->message($http_res->message);

    if ($http_res->is_success) {
        my $json = $json->utf8->decode( $http_res->decoded_content );
        $res->_parse_json($json);
        $res->is_success(1);
    } else {
        $res->content($http_res->decoded_content);
    }

    return $res;
}

sub new_request {
    my $self = shift;

    return Net::Google::Analytics::V4::Request->new(@_);
}

1;

