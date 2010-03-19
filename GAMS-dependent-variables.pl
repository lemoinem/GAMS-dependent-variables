#!/usr/bin/perl

 # Licensed under 3-clause BSD License:
 # Copyright © 2010, Mathieu Lemoine
 # All rights reserved.
 #
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions are met:
 #  * Redistributions of source code must retain the above copyright
 #    notice, this list of conditions and the following disclaimer.
 #  * Redistributions in binary form must reproduce the above copyright
 #    notice, this list of conditions and the following disclaimer in the
 #    documentation and/or other materials provided with the distribution.
 #  * Neither the name of Mathieu Lemoine nor the
 #    names of contributors may be used to endorse or promote products
 #    derived from this software without specific prior written permission.
 #
 # THIS SOFTWARE IS PROVIDED BY Mathieu Lemoine ''AS IS'' AND ANY
 # EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 # WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 # DISCLAIMED. IN NO EVENT SHALL Mathieu Lemoine BE LIABLE FOR ANY
 # DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 # (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES
 # LOSS OF USE, DATA, OR PROFITSOR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 # ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 # SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

sub trim ($)
{
    my $arg = $_[0];
    $arg =~ s/^\s+//;
    $arg =~ s/\s+$//;
    return $arg;
}

use File::Temp qw/ tempfile tempdir /;
use Shell qw/sed tac/;

exit 1 unless @ARGV >= 2;
exit 2 unless -r $ARGV[0];

print $directory = tempdir or die $!." at ".$.;
print "\n";

# Create dictionary sed script file

open rev_script, ">$directory/rev-script" or die $!." at ".$.;
open display_dependent, ">$directory/display-dependent.inc" or die $!." at ".$.;
open dictionary, "<$ARGV[0]" or die $!." at ".$.;

while(<dictionary>)
{
    ($comment, $_) = map {trim $_} split /:/;
    ($_, $comment) = ($comment, '') if $_ eq ''; # if no comment
    next if $_ eq ''; # if no definition
    ($declaration, $definition) = map {trim $_} split /=/;
    print display_dependent "Parameter $declaration $comment;\n$declaration = $definition;\n" or die $!." at ".$.;
    $name = $declaration;
    if ($declaration =~ /^([^\(]+)\(([^\)]+)\)$/)
    {
        $declaration = ($name = trim $1).'\\(';
        @args = map {trim $_} split /,/, $2;
        my $i = 0;
        foreach (@args)
        {
            $declaration .= '([^,)]+)';
            $declaration .= ',' unless $i++ == $#args;
            $definition =~ s/\b$_\b/\\$i/ig;
        }
        $declaration .= '\\)';
        $definition =~ s/\//\\\//g;
        $definition =~ s/\.l(\s*\()/\1/g;
        $definition =~ s/;$//g;
        print rev_script "s/\\b$declaration/($definition)/g\n" or die $!." at ".$.;
    }
    print display_dependent "Display $name;\n\n" or die $!." at ".$.;
}

close dictionary or die $!." at ".$.;
close rev_script or die $!." at ".$.;

tac "$directory/rev-script", ">$directory/sed-script" and die $!." at ".$.;

# Call sed script

shift @ARGV;

sed '-rf', "$directory/sed-script", $_, ">$directory/$_" and die $!." at ".$. foreach (@ARGV);