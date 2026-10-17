#!/usr/bin/env perl
use strict;
use warnings;
use Encode qw(decode encode FB_CROAK);
use Cwd qw(abs_path);
use File::Basename qw(dirname);

# Shared implementation for both launchers. Requires Git and Perl with Encode.
sub git_output {
    open my $pipe, '-|', 'git', @_ or die "Cannot start Git: $!\n";
    binmode $pipe;
    local $/;
    my $out = <$pipe> // '';
    close $pipe or die "Git command failed: git @_\n";
    return $out;
}
my $script = __FILE__;
$script =~ tr{\\}{/};
chdir dirname(abs_path($script)) or die "Cannot enter script directory: $!\n";
my $root = git_output('rev-parse', '--show-toplevel');
$root =~ s/\r?\n\z//;
chdir $root or die "Cannot enter project root: $!\n";
my @files = split /\0/, git_output('ls-files', '--cached', '--others', '--exclude-standard', '-z');
my %seen;
my ($converted, $skipped) = (0, 0);
for my $file (@files) {
    next if $seen{$file}++;
    next unless -f $file;
    if (-l $file || $file =~ m{(?:^|/)\.git(?:/|$)}) { $skipped++; next; }
    my @attrs = split /\0/, git_output('check-attr', '-z', 'text', 'eol', 'working-tree-encoding', '--', $file);
    my %attr;
    while (@attrs) { my ($path, $key, $value) = splice @attrs, 0, 3; $attr{$key} = $value; }
    # Explicit binary / CRLF policies take precedence over normalization.
    if ($attr{text} eq 'unset' || $attr{eol} eq 'crlf') { $skipped++; next; }
    # Auto/unspecified text is restricted to known source/document formats.
    my $known = $file =~ /\.(?:cs|csproj|sln|slnx|props|targets|axaml|xaml|xml|json|jsonc|ya?ml|toml|ini|config|md|txt|csv|tsv|html?|css|scss|less|[cm]?js|jsx|tsx?|vue|svelte|py|rb|php|java|kt|go|rs|c|h|cpp|hpp|sql|graphql|sh|ps1|psm1|psd1|pl|bat|cmd|svg|resx|editorconfig|gitignore|gitattributes)\z/i
        || $file =~ m{(?:^|/)(?:\.editorconfig|\.gitignore|\.gitattributes|Dockerfile|Makefile|LICENSE|README)\z}i;
    if (!$known && $attr{text} ne 'set') { $skipped++; next; }
    open my $in, '<:raw', $file or die "Cannot read $file: $!\n";
    local $/;
    my $bytes = <$in> // '';
    close $in or die "Cannot close $file: $!\n";
    next unless length $bytes;
    my ($bom, $encoding) = ('', 'UTF-8');
    if ($bytes =~ /\A(?:\xFF\xFE\x00\x00|\x00\x00\xFE\xFF)/) {
        $bom = substr($bytes, 0, 4, ''); $encoding = $bom eq "\xFF\xFE\x00\x00" ? 'UTF-32LE' : 'UTF-32BE';
    } elsif ($bytes =~ /\A(?:\xFF\xFE|\xFE\xFF)/) {
        $bom = substr($bytes, 0, 2, ''); $encoding = $bom eq "\xFF\xFE" ? 'UTF-16LE' : 'UTF-16BE';
    } elsif ($bytes =~ /\A\xEF\xBB\xBF/) { $bom = substr($bytes, 0, 3, ''); }
    # Do not guess legacy encodings or contradict a declared working-tree encoding.
    my $declared = $attr{'working-tree-encoding'};
    if ($declared ne 'unspecified' && $declared ne 'unset') {
        my $canonical = uc($declared); $canonical =~ s/[-_]//g;
        my $actual = uc($encoding); $actual =~ s/[-_]//g;
        if ($canonical ne $actual && !($canonical eq 'UTF16' && $actual =~ /^UTF16/ && length $bom)) { $skipped++; next; }
    }
    my $text = eval { decode($encoding, $bytes, FB_CROAK) };
    if ($@ || $text =~ /[\x00-\x08\x0B\x0E-\x1F\x7F]/) { $skipped++; next; }
    next unless $text =~ s/\r\n?/\n/g;
    my $output = $bom . encode($encoding, $text, FB_CROAK);
    open my $out, '>:raw', $file or die "Cannot write $file: $!\n";
    print {$out} $output or die "Cannot write $file: $!\n";
    close $out or die "Cannot close $file: $!\n";
    print "Converted: $file\n";
    $converted++;
}
print "\nProject root: $root\nFinished. Converted: $converted, skipped: $skipped\n";
