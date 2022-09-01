#!/usr/bin/env raku
use Text::CSV::LibCSV;
use Text::Utils :normalize-string;

#================================================================
# TODO: comment out the following line before publishing
use lib <../lib >; # TODO: comment out this line before publishing
#================================================================

use GnuCash::HancockWhitney;
use TXF;
use TXF::Utils;

#use CLI::Help;

my $local-dir = "./private";
my $data-dir;
if %*ENV<PRIVATE_FINANCIAL_DATA_SOURCE_DIR>:exists {
    $data-dir = %*ENV<PRIVATE_FINANCIAL_DATA_SOURCE_DIR>;
}
unless $data-dir.IO.d {
    note qq:to/HERE/;
    WARNING: A private data source directory was not found or defined.
      Define one by assigning it to the environment variable
      'PRIVATE_FINANCIAL_DATA_SOURCE_DIR'.
    Exiting...
    HERE
    exit;
}

=begin comment
  'hancock/chckng/0-statement-2021-12-21.pdf'
  'hancock/chckng/April 21, 2022.pdf'
  'hancock/mmkt/0-statement-2021-09-28.pdf'
  'hancock/mmkt/April 27, 2022.pdf'
  'hancock/mmkt/December 27, 2021.pdf'
  'hancock/visa/0-statement-2022-01-13.pdf'
  'hancock/visa/April 13, 2022.pdf'
  'synovus/chckng/EStatement-2020-06-03-31250.pdf'
  'synovus/mmkt/EStatement-2020-08-17-47887.pdf'
=end comment

use File::Find;
use Date::Names;

my $Delete  = 0;
my $debug   = 0;
my $convert = 0;
my $extract = 0;
if not @*ARGS.elems {
    print qq:to/HERE/;
    Usage: {$*PROGRAM.basename} go | Delete [debug]

    go
      Collects the Hancock-Whitney and Synovus file names and makes a
      branded and typed copy of each with the proper ISO dates.

    Delete
      Deletes the files with the "weird" file names after there is
      a safe copy named in the new standard format.

    convert
      Converts any old "standard" transformed files to a name that 
      identifies the brand ('hwb' or 'syn') and the type of statement: 
      'ck' (checking), 'cr' (credit card), 'sa' (savings).
      Designed for a one-time format use with other programs
      such as <https://bankstatementconverter.com>.

    extract
      Extracts the first two lines of the HWB CSV files and classifies
      sends to stdout.
    HERE
    exit;
}

for @*ARGS {
    when /^d/ { ++$debug }
    when /^D/ { ++$Delete }
    when /^c/ { ++$convert }
    when /^e/ { ++$extract }
}

#my $dir = '.';
my $dir = $data-dir;
enum STyp <Pdf Ofx Csv>;
my %OFX-fils  = collect-files :$dir, :suff(Ofx), :$debug;
my %CSV-fils  = collect-files :$dir, :suff(Csv), :$debug;
my %PDF-fils  = collect-files :$dir, :suff(Pdf), :$debug;

sub collect-files(:$dir, STyp :$suff, :$debug --> Hash) is export {
    my (%fils, @fils);
    with $suff {
        when /Pdf/ {
            @fils = find :$dir, :type("file"), :name(/:i '.' pdf $/);
        }
        when /Ofx/ {
            @fils = find :$dir, :type("file"), :name(/:i '.' ofx $/);
        }
        when /Csv/ {
            @fils = find :$dir, :type("file"), :name(/:i '.' csv $/);
        }
        default {
            die "FATAL: Unknown value for \$suff: '$suff'";
        }
    }

    # put collected files into a hash
    for @fils -> $f {
        # ignore some
        next if $f ~~ /:i psrr | USAA | USAFA | canterbury/;
        my ($brand, $acct);
        with $f {
            when /:i han|hw  / { $brand = 'hwb'; }
            when /:i syno / { $brand = 'syn'; }
        }

        with $f {
            when /:i chkng / { $acct = 'chkng'; }
            when /:i mmkt  / { $acct = 'mmkt'; }
            when /:i visa  / { $acct = 'visa'; }

            default {
                die "FATAL: Unexpected path '$f'";
            }
        }

        =begin comment
        if $f ~~ /:i han|hw  / {
            $brand = 'hwb';
        }
        elsif $f ~~ /:i syno / {
            $brand = 'syn';
        }
        else {
            die "FATAL: Unexpected path '$f'";
        }
        =end comment

        %fils{$f}<brand> = $brand // '';
        %fils{$f}<acct>  = $acct  // '';
    }
    %fils
}

if $debug {
    say "DEBUG: PDF files found:";
    for %PDF-fils.keys.sort -> $f {
        my $brand = %PDF-fils{$f}<brand>;
        my $acct  = %PDF-fils{$f}<acct>;
        say "  brand: '$brand'; path '$f'";
    }
    say "DEBUG: OFX files found:";

    for %OFX-fils.keys.sort -> $f {
        my $brand = %PDF-fils{$f}<brand>;
        my $acct  = %PDF-fils{$f}<acct>;
        say "  brand: '$brand'; path '$f'";
    }
    say "DEBUG: CSV files found:";

    for %CSV-fils.keys.sort -> $f {
        my $brand = %PDF-fils{$f}<brand>;
        my $acct  = %PDF-fils{$f}<acct>;
        say "  brand: '$brand'; path '$f'";
    }
}

# check for old transformed format
my @badpdf;
#for @PDF-fils -> $f {
for %PDF-fils.keys.sort -> $f {
    if $f ~~ / '/'? '0-statement' / {
        @badpdf.push: $f;
    }
}
my $nb = @badpdf.elems;
if $convert and $nb {
    note "FATAL: $nb files have NOT been converted to the new transformed format yet:";
    for @badpdf -> $oldpath {
        # get the old path parts
        my $dirname  = $oldpath.IO.dirname;
        my $basename = $oldpath.IO.basename;
        note "  bad file name |$dirname| |$basename| (path: |$oldpath|)";
        my $newbasename = change-name :$dirname, :$basename, :$debug;
        my $newpath = "$dirname/$newbasename";
        note "    new name    |$dirname| |$newbasename| (path: |$newpath|)";
        if $newpath.IO.r {
            note "    new name EXISTS as a readable file";
            if $Delete {
                note "    DELETING old file.";
                unlink $oldpath;
            }
        }
        else {
            copy $oldpath, $newpath;
        }
    }
    note "Exiting."; exit;
}

if $nb {
    #note "FATAL: $nb files have NOT been converted to the new transformed format yet:";
    note "WARNING: $nb files have NOT been converted to the new transformed format yet:";
    note "  $_" for @badpdf;
    note "Use the 'convert' option to correct the names.";
    # exit;
}


##########################################################
enum FType <Copy HW>;
# Provide a hash for copied files transformed to desired format
my %Copied-fils; # $type = Copy

# provide a hash for files eligible to delete (files with original
# format from Hancock-Whitney, but keyed with the transformed names)
my %HW-fils; # $type = HW

my $DN = Date::Names.new;
#FILE: for @PDF-fils -> $pfil {
FILE: for %PDF-fils.keys -> $pfil {
    my $basename = $pfil.IO.basename;
    my $dirname  = $pfil.IO.dirname;

    if $debug {
        say "DEBUG: pfil: $pfil";
        say "    dirname:   $dirname";
        say "   basename:   $basename";
        next;
    }

    my ($mtype, $match) = get-match $basename; # Copy or HW
    if $mtype ~~ Copy {
        # so $pfil is type Copy
        # put $pfil as key in Copied-fils
        my $mfil = "$dirname/$match";
        %Copied-fils{$pfil} = $mfil;
    }
    elsif $mtype ~~ HW {
        # so $pfil is type HW
        # put $pfil as value in %HW-fils keyed by $mfil so we get a proper date sort
        my $mfil = "$dirname/$match";
        %HW-fils{$mfil} = $pfil;
    }
}

say "Checking for uncopied Hancock-Whitney files...";
if 0 {
    my $nf = 0;
    for %HW-fils.keys.sort -> $copied-fil {
        my $hw-fil = %HW-fils{$copied-fil};
        # make sure both exist
        if not $hw-fil.IO.r {
            say "ERROR: Original HW file '$hw-fil' does NOT exist!";
            ++$nf;
        }
        if not $copied-fil.IO.r {
            say "ERROR: Copied file '$copied-fil' does NOT exist. Attempting a recopy.";
            copy $hw-fil, $copied-fil;
            say "Exiting for user to rerun."; exit;
            ++$nf;
        }
    }
    if $nf {
        say "FATAL: $nf files are unexpectedly missing...exiting.";
        exit;
    }
    say "  No problems found.";
}


say "Existing transformed file names:";
for %Copied-fils.keys.sort -> $f {
    say "  $f";
}

if $extract {
    say "Extracting two CSV lines from each HWB file";
    say "DEBUG: CSV files found:";
    for %CSV-fils.keys.sort -> $f {
        my $brand = %CSV-fils{$f}<brand> // '';
        my $acct  = %CSV-fils{$f}<acct>  // '';
        note "DEBUG: 2 csv, brand '$brand', acct '$acct', path: '$f'" if 1 or $debug;
        next if $brand eq 'syn';
        
        # extract N lines
        my $n = 4;
        if $f.IO.r {
            say "Path: $f";
            for $f.IO.lines.kv -> $i, $line {
                last if $i > $n;
                say "  $line";
            }
        }
        else {
            die "FATAL: Unable to open file $f";
        }
    }
}

if $Delete {
    say "Selecting files to delete:";
    my $nd = 0;
    for %HW-fils.keys.sort -> $copied-fil {
        my $hw-fil = %HW-fils{$copied-fil};
        # make sure it exists
        if not $hw-fil.IO.r {
            say "ERROR: Original HW file '' does NOT exist!";
            exit;
        }
        my $ans = prompt "Delete file '$hw-fil' (Y/n/quit) ";
        if $ans ~~ /:i ^y/ {
            say "  Unlinking file '$hw-fil'...";
            unlink $hw-fil;
            ++$nd;
        }
        elsif $ans ~~ /:i ^q/ {
            say "  Quitting this program.";
            my $s = $nd != 1 ?? 's' !! '';
            if $nd {
                say "Deleted $nd file$s";
            }
            else {
                say "No files were deleted.";
            }
        }
        else {
            say "  Leaving the file untouched.";
        }
    }
    my $s = $nd != 1 ?? 's' !! '';
    if $nd {
        say "Deleted $nd file$s";
    }
    else {
        say "No files were deleted.";
    }
}

say "Normal end.";

#### subroutines ####
sub change-name(:$dirname!, :$basename, :$debug --> Str) is export {
    my $newbasename = "";
    my $typ = "";
    with $dirname {
        when /checking/ { $typ = 'chk' }
        when /mmkt/     { $typ = 'sav' }
        when /visa/     { $typ = 'cre' }

        =begin comment
        when $_ eq 'checking' { $typ = 'checking' }
        when $_ eq 'mmkt' { $typ = 'mmkt' }
        when $_ eq 'visa' { $typ = 'visa' }
        =end comment

        default {
            die "FATAL: Unknown dirname '$dirname'";
        }
    }

    if $basename ~~ /^ '0-statement-' (\d**4) '-' (\d\d) '-' (\d\d) '.pdf' $/ {
        my $y = ~$0;
        my $m = ~$1;
        my $d = ~$2;
        $newbasename = "{$typ}-statement-{$y}-{$m}-{$d}.pdf";
    }
    else {
        die "FATAL: Unexpected old file basename: $basename";
    }
    $newbasename;

} # sub change-name(:$dirname!, :$basename, :$debug --> Str) is export {

sub get-match($basename, :$debug --> List) is export {
    # Given a pdf file name, determine its matching
    # name in the transformation HW => Copy where HW
    # is the original Hancock-Whitney format of 'month day, year'
    # and Copy is the transformed name of yyyy-mm-dd
    my $match;
    my FType $intype; # Copy or HW

    #   my $fcopy = "0-statement-$yy-$mm-$dd.pdf";
    if $basename ~~ / '0-statement-' (\d**4) '-' (\d\d) '-' (\d\d) '.pdf' $/ {
        $intype = Copy;

        my $y   = ~$0;
        my $m   = +$1;
        my $d   = ~$2;

        # form the matched name in format 'month day, year
        my $month-str = $DN.mon($m);
        $match = $month-str ~ " $d, $y";
    }

    # original and undesired format: 'checking/February 21, 2022.pdf'
    elsif $basename ~~ / (<[JFMASOND]> \S+) \h+ (\d+) ',' \h+ (\d**4) '.pdf' $/ {
        $intype = HW;

        my $m   = ~$0;
        my $d   = ~$1;
        my $y   = ~$2;

        # just in case:
        if $d.chars == 1 {
            $d = '0' ~ $d;
        }

        # form the matched name
        # convert to yyyy-mm-dd format:
        my $yy = $y;
        my $mm = $DN.mon2num($m);
        if $mm.chars == 1 {
            $mm = '0' ~ $mm;
        }
        my $dd = $d;

        my $fcopy = "0-statement-$yy-$mm-$dd.pdf";
        #my $cfil  = "$dir/$fcopy";
        $match = "0-statement-$yy-$mm-$dd.pdf";
    }

    $intype, $match;
} # sub get-match($basename, :$debug --> List) is export {

sub csvhdrs2X($csvfile --> Hash) {
    # given a CSV file with headers, map the appropriate
    # header to the X field name

    # get the field names from the first row of the file
    my $delim = csv-delim $csvfile;
    my Text::CSV::LibCSV $parser .= new(:auto-decode('utf8'), :delimiter($delim));
    my @rows = $parser.read-file($csvfile);
    my @fields = @(@rows[0]);
    my $len = @fields.elems;

    # make sure the headers are normalized before assembling into a check string
    my $fstring = '';
    for 0..^$len -> $i {
        @fields[$i] = normalize-string @fields[$i];
        $fstring ~= '|' if $i;
        $fstring ~= @fields[$i];
    }

    #=begin format
    # check the field string against known formats
    my %Xfields = find-known-formats $fstring, $csvfile;
    if not %Xfields.elems {
        # we must abort unless we can get an alternative
        # by allowing the user to provide a map in an input
        # file
    }
    #=end format
    return %Xfields;
}
