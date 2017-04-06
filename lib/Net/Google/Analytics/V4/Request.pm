package Net::Google::Analytics::V4::Request;

use strict;
use warnings;

# ABSTRACT: Google Analytics Core Reporting API version 4 request

use Class::XSAccessor
    accessors => [ qw(
        view_id
        filters_expression
        order_bys
        start_date end_date
        metrics dimensions

        page_token
        page_size
        include_empty_rows
        hide_totals
        hide_value_ranges

        alt
        fields
        sampling_level
        pretty_print
        quota_user
    ) ],
    constructor => 'new';

my @param_map = (
    alt           => 'alt',
    fields        => 'fields',
    pretty_print  => 'prettyPrint',
    quota_user    => 'quotaUser',
);

my %request_map = (
    view_id               => 'viewId',

    start_date            => 'startDate',
    end_date              => 'endDate',
    metrics               => 'metrics',
    dimensions            => 'dimensions',

    filters_expression    => 'filtersExpression',
    page_token            => 'pageToken',
    page_size             => 'pageSize',
    include_empty_rows    => 'includeEmptyRows',
    hide_totals           => 'hideTotals',
    hide_value_ranges     => 'hideValueRanges',

    sampling_level        => 'samplingLevel',

    field_name            => 'fieldName',
    order_type            => 'orderType',
    sort_order            => 'sortOrder',
);

sub params {
    my $self = shift;
    my @params;

    for (my $i=0; $i<@param_map; $i+=2) {
        my $from = $param_map[$i];
        my $to   = $param_map[$i+1];

        my $value = $self->{$from};
        push(@params, $to => $value) if defined($value);
    }

    return @params;
}

sub report_request {
    my $self   = shift;
    my $report = {};

    my @required = qw/view_id start_date end_date/;

    for my $name (@required) {
        my $value = $self->{$name};
        die("parameter $name is empty")
            if !defined($value) || $value eq '';
    }

    #

    my @scalars = qw/view_id filters_expression page_token page_size sampling_level/;
    for my $k ( @scalars ) {
        $report->{ $request_map{$k} } = $self->{$k} if $self->{$k};
    }

    #

    my @booleans = qw/include_empty_rows hide_totals hide_value_ranges/;
    for my $k ( @booleans ) {
        my $value = lc( $self->{$k} ) if $self->{$k};

        if ($value && ($value =~ /true|false/)) {
            $report->{ $request_map{$k} } = $value;
        }
    }

    #

    if ( $self->dimensions ) {
        $report->{dimensions} = [];
        my @entities = split ',', $self->dimensions;

        for my $k ( @entities ) {
            chomp $k; $k =~ s/\s+//g;
            push @{$report->{dimensions}}, { name => $k };
        }
    }

    if ( $self->metrics ) {
        $report->{metrics} = [];
        my @entities = split ',', $self->metrics;

        for my $k ( @entities ) {
            chomp $k; $k =~ s/\s+//g;
            push @{$report->{metrics}}, { expression => $k };
        }
    }


    #

    $report->{dateRanges} = [{
        $request_map{start_date} => $self->start_date,
        $request_map{end_date}   => $self->end_date,
    }];

    #

    if ( $self->order_bys ) {
        $report->{orderBys} = [];

        for my $ob ( @{$self->order_bys} ) {
            my $r_ob = {};

            for my $k ( keys %$ob ) {
                $r_ob->{ $request_map{$k} } = $ob->{$k};
            }

            push @{$report->{orderBys}}, $r_ob;
        }
    }


    return { reportRequests => [ $report ] };
}

1;

