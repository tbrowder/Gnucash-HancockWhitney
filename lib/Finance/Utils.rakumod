unit module Finance::Utils;

use Text::CSV::LibCSV;
use Text::Utils :normalize-string;
use Config::TOML;

sub csv-delim($csv-fname) is export {
    # given a CSV type file, guess the delimiter
    # from the extension
    my $delim = ','; # default
    if $csv-fname ~~ /'.csv'$/ {
        ; # ok, default
    }
    elsif $csv-fname ~~ /'.tsv'$/ {
        $delim = "\t";
    }
    elsif $csv-fname ~~ /'.txt'$/ {
        $delim = "\t";
    }
    elsif $csv-fname ~~ /'.psv'$/ {
        $delim = '|';
    }
    else {
        die "FATAL: Unable to handle 'csv' delimiter for file '{$csv-fname.IO.basename}'";
    }
    return $delim;
}

sub find-known-formats($fstring, $csvfile --> Hash) is export {
}
