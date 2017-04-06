package Net::Google::Analytics::V4::Report;

use strict;
use warnings;

# ABSTRACT: Google Analytics Core Reporting API version 4 report

use Class::XSAccessor
    accessors => [ qw(
        rows
        _totals
        _minimums
        _maximums
        _column_headers
        is_data_golden
        next_page_token
        sampling_space_sizes
        samples_read_counts
    ) ],
    constructor => 'new';

sub error_message {
    my $self = shift;

    return join(' ', $self->code,  $self->message, $self->content);
}

sub _parse_report {
    my ($self, $raw) = @_;

    $self->next_page_token( $raw->{nextPageToken} );

    #

    my $column_headers = [];

    if ($raw->{columnHeader}{metricHeader} &&
        $raw->{columnHeader}{metricHeader}{metricHeaderEntries}) {

        for my $metric_header (@{ $raw->{columnHeader}{metricHeader}{metricHeaderEntries} }) {
            push(@$column_headers, {
                name        => _parse_column_name($metric_header->{name}),
                data_type   => $metric_header->{type},
                column_type => 'METRIC',
            });
        }
    }

    if ($raw->{columnHeader}{dimensions}) {
        for my $dimension_name (@{ $raw->{columnHeader}{dimensions} }) {
            push(@$column_headers, {
                name        => _parse_column_name($dimension_name),
                column_type => 'DIMENSION',
            });
        }
    }

    $self->_column_headers( $column_headers );

    #

    if ( $raw->{data} ) {
        my $class = Net::Google::Analytics::Row->_gen_class($column_headers);
        my @rows = map {
            my $row = [];
            if ( $_->{metrics} ) { push @$row, @{$_->{metrics}->[0]->{values}} }
            if ( $_->{dimensions} ) { push @$row, @{$_->{dimensions}} }
            $class->new($row)
        } @{ $raw->{data}{rows} };
        $self->rows(\@rows);

        $self->is_data_golden( $raw->{data}{isDataGolden} );
        $self->sampling_space_sizes( $raw->{data}{samplingSpaceSizes} );
        $self->samples_read_counts( $raw->{data}{samplesReadCounts} );

        my @metrics = $self->metrics;

        for my $n ( qw/totals minimums maximums/ ) {
            my $numbers = {};
            if ( $raw->{data}{$n}->[0]) {
                my @values = @{ $raw->{data}{$n}->[0]->{values} };

                for (my $i=0; $i < (scalar @values); $i++ ) {
                    $numbers->{ $metrics[$i] } = $values[$i];
                }

                my $n_name = '_' . $n;
                $self->$n_name( $numbers );
            }
        }
    }
}

sub _parse_column_name {
    my $name = shift;

    my ($res) = $name =~ /^(?:ga|rt):(\w{1,64})\z/
        or die("invalid column name: $name");

    # convert camel case
    $res =~ s{([^A-Z]?)([A-Z]+)}{
        my ($prev, $upper) = ($1, $2);
        $prev . ($prev =~ /[a-z]/ ? '_' : '') . lc($upper);
    }ge;

    return $res;
}

sub num_rows {
    my $self = shift;

    return scalar(@{ $self->rows });
}

sub metrics {
    my $self = shift;

    return $self->_columns('METRIC');
}

sub dimensions {
    my $self = shift;

    return $self->_columns('DIMENSION');
}

sub totals {
    my ($self, $metric) = @_;

    return $self->_totals->{$metric};
}

sub maximums {
    my ($self, $metric) = @_;

    return $self->_maximums->{$metric};
}

sub minimums {
    my ($self, $metric) = @_;

    return $self->_minimums->{$metric};
}

sub _columns {
    my ($self, $type) = @_;

    my $column_headers = $self->_column_headers;
    my @results;

    for my $column_header (@$column_headers) {
        if ($column_header->{column_type} eq $type) {
            push(@results, $column_header->{name});
        }
    }

    return @results;
}


1;

