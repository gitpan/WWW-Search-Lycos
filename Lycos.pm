# Lycos.pm
# by Wm. L. Scheding and Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: Lycos.pm,v 1.23 2000/12/20 16:26:04 mthurn Exp $

=head1 NAME

WWW::Search::Lycos - class for searching Lycos 

=head1 SYNOPSIS

  use WWW::Search;
  my $oSearch = new WWW::Search('Lycos');
  my $sQuery = WWW::Search::escape_query("+sushi restaurant +Columbus Ohio");
  $oSearch->native_query($sQuery);
  while (my $oResult = $oSearch->next_result())
    print $oResult->url, "\n";

=head1 DESCRIPTION

This class is a Lycos specialization of L<WWW::Search>.  It handles
making and interpreting Lycos-site searches F<http://www.Lycos.com>.

This class exports no public interface; all interaction should
be done through L<WWW::Search> objects.

=head1 NOTES

www.lycos.com is sometimes slow to respond; but I have not had a
problem with the default timeout.

www.lycos.com does not give the score, date, nor size of the pages at
the resulting URLs; therefore change_date(), score(), and size() will
never have a value.

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>.

=head1 BUGS

Please tell the author if you find any!

=head1 TESTING

This module adheres to the WWW::Search test mechanism.
See $TEST_CASES below.

=head1 AUTHOR

As of 1998-12-07, C<WWW::Search::Lycos> is maintained by Martin Thurn
(MartinThurn@iname.com).

C<WWW::Search::Lycos> was originally written by Martin Thurn,
based on C<WWW::Search::Yahoo> version 1.12 of 1998-10-22.

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=head1 VERSION HISTORY

If it is not listed here, then it was not a meaningful nor released revision.

=head2 2.15, 2000-12-19

rewrite using HTML::TreeBuilder, correcting parsing errors

=head2 2.14, 2000-09-21

was missing GUI results with no description

=head2 2.13, 2000-09-18

BUGFIX for missing page count number

=head2 2.12, 2000-09-15

parse new output format

=head2 2.11, 2000-06-15

new method gui_query, and parse new output format

=head2 2.09, 1999-12-26

output format fixes, and query string changes for searching Lycos.com (dbradford@bdctechnologies.com)

=head2 2.08, 1999-12-22

point to new path on lycos.com (thanks to David Bradford dbradford@bdctechnologies.com)

=head2 2.07, 1999-12-10

more output format fixes, and missing 'next' link for Sites

=head2 2.05, 1999-12-03

handle new url and new output format for Lycos::Sites.pm

=head2 2.04, 1999-10-22

use strip_tags();
extract real URL from www.lycos.com's redirection URL

=head2 2.03, 1999-10-05

now uses hash_to_cgi_string()

=head2 2.02, 1999-09-30

Now able to get Web Sites results via child module Sites.pm

=head2 2.01, 1999-07-13

=head2 1.04, 1999-04-30

Now uses lycos.com's advanced query format.

=head2 1.02, 1998-12-10

First public release after being adopted by Martin Thurn.

=cut

#####################################################################

package WWW::Search::Lycos;

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw(WWW::Search Exporter);

$VERSION = '2.15';
$MAINTAINER = 'Martin Thurn <MartinThurn@iname.com>';

use Carp;
use HTML::Form;
use HTML::TreeBuilder;
use URI::Escape;
use WWW::Search qw( generic_option strip_tags unescape_query );
use WWW::SearchResult;

sub gui_query
  {
  my ($self, $sQuery, $rh) = @_;
  $self->{'_options'} = {
                         'search_url' => 'http://www.lycos.com/srch/',
                         'query' => $sQuery,
                         'lpv' => 1,
                         'loc' => 'searchhp',
                        };
  return $self->native_query($sQuery, $rh);
  } # gui_query


sub native_setup_search
  {
  my ($self, $native_query, $native_options_ref) = @_;
  $self->{_debug} = $native_options_ref->{'search_debug'};
  $self->{_debug} = 2 if ($native_options_ref->{'search_parse_debug'});
  $self->{_debug} = 0 if (!defined($self->{_debug}));

  # lycos.com returns 10 hits per page no matter what.
  $self->{'_hits_per_page'} = 10;

  $self->{agent_e_mail} = 'MartinThurn@iname.com';
  $self->user_agent('non-robot');

  $self->{_next_to_retrieve} = 1;
  $self->{'_num_hits'} = 0;

  # The default search uses lycos.com's Advanced Search mechanism:
  if (!defined($self->{_options}))
    {
    $self->{'search_base_url'} = 'http://lycospro.lycos.com';
    
    # -------------------------------------------------------------------------
    # Modifications: 12/26/99 by dbradford@bdctechnologies.com
    # New Query String: As of 12/26/99, here is what it looks like querying for "linux"
    # Query String: http://lycospro.lycos.com/srchpro/?loc=searchhp&lpv=1&query=linux&t=all&type=websites
    # Removed these options:
    #		'maxhits' => $self->{_hits_per_page},
    #       'matchmode' => 'or',
    #       'cat' => 'lycos',
    #       'mtemp' => 'nojava',
    #       'adv' => 1,
    #
    # Added these one in:
    #		'lpv' => '1',
    #		'loc' => 'searchhp',
    #		'type' => 'websites',
    #		't' => 'all',
    #		'query' => $native_query,
    # -------------------------------------------------------------------------
    $self->{_options} = {
                         'search_url' => $self->{'search_base_url'} .'/srchpro/',
						 'lpv' => '1',
						 'loc' => 'searchhp',
						 'type' => 'websites',
						 't' => 'all',
						 'query' => $native_query,
                        };
    } # if
  $self->{_options}->{'query'} = $native_query;

  my $options_ref = $self->{_options};

  # Copy in options which were passed in our second argument:
  if (defined($native_options_ref)) 
    {
    foreach (keys %$native_options_ref) 
      {
      $options_ref->{$_} = $native_options_ref->{$_};
      } # foreach
    } # if

  # Copy in options which were set by a child object:
  if (defined($self->{'_child_options'})) 
    {
    foreach (keys %{$self->{'_child_options'}}) 
      {
      $self->{'_options'}->{$_} = $self->{'_child_options'}->{$_};
      } # foreach
    } # if

  # Finally figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});

  } # native_setup_search


# private
sub native_retrieve_some
  {
  my ($self) = @_;
  print STDERR " *   Lycos::native_retrieve_some()\n" if $self->{_debug};
  
  # Fast exit if already done:
  return undef if (!defined($self->{_next_url}));
  my $sCurrURL = $self->{_next_url};
  # If this is not the first page of results, sleep so as to not
  # overload the server:
  $self->user_agent_delay if 1 < $self->{'_next_to_retrieve'};
  
  # Get some:
  print STDERR " *   sending request ($sCurrURL)\n" if $self->{_debug};
  # print STDERR " *   sending request ($sCurrURL)\n";
  my $response = $self->http_request('GET', $sCurrURL);
  $self->{response} = $response;
  if (!$response->is_success)
    {
    return undef;
    } # if
  
  $self->{'_next_url'} = undef;
  $self->{'_next_to_retrieve'} += $self->{'_hits_per_page'};
  print STDERR " *   got response\n" if $self->{_debug};

  # parse the output
  my $tree = new HTML::TreeBuilder;
  $tree->parse($response->content);
  $tree->eof;
  my $hits_found = 0;

  # Each URL result is in a <LI> tag:
  my @aoLI = $tree->look_down('_tag', 'li');
  foreach my $oLI (@aoLI)
    {
    print STDERR " + LI == ", $oLI->as_HTML if 1 < $self->{'_debug'};
    # actual value:
    # <li><font face="verdana" size="-1"><a href="http://click.hotbot.com/director.asp?id=1&amp;target=http://www.posta.suedtirol.com/&amp;query=Martin+Thurn&amp;rsource=LCOSADVF">Gasthof Post - St. <b>Martin</b> in <b>Thurn</b>, S. <b>Martin</b> in Badia, Pustertal, Val Pusteria, S&Atilde;&frac14;dtirol, Alto Adige, Italy</a> - Diese Web-Seite verwendet Frames. Frames werden von Ihrem Browser aber nicht unterst&Atilde;&frac14;tzt. </font><br><i><font color="#000000" face="verdana" size="-2">http://www.posta.suedtirol.com/</font></i><p>

    # The URL is in the last <FONT> tag:
    my @aoFONT = $oLI->look_down('_tag', 'font');
    $oFONT = $aoFONT[-1];
    next unless ref($oFONT);
    my $sURL = $oFONT->as_text;
    $oFONT->detach;
    $oFONT->delete;
    print STDERR " +   URL   == $sURL\n" if 1 < $self->{'_debug'};

    # The title is in the first <A> tag:
    my $oA = $oLI->look_down('_tag', 'a');
    next unless ref($oA);
    my $sTitle = $oA->as_text;
    $oA->detach;
    $oA->delete;
    $sTitle = &strip_tags($sTitle);
    print STDERR " +   TITLE == $sTitle\n" if 1 < $self->{'_debug'};

    # Now, the description is the text of the entire <LI>:
    my $sDesc = $oLI->as_text;
    $sDesc =~ s!\A - !!;

    my $hit = new WWW::SearchResult;
    $hit->add_url($sURL);
    $hit->title($sTitle);
    $hit->description($sDesc);
    push(@{$self->{cache}}, $hit);
    $self->{'_num_hits'}++;
    $hits_found++;
    } # foreach
  # See if there is a NEXT button:
  my @aoCENTER = $tree->look_down('_tag', 'center');
 CENTER:
  foreach my $oCENTER (@aoCENTER)
    {
    next CENTER unless ref $oCENTER;
    print STDERR " + CENTER == ", $oCENTER->as_HTML, "\n" if 1 < $self->{'_debug'};
    my @aoA = $oCENTER->look_down('_tag', 'a');
 A:
    foreach my $oA (@aoA)
      {
      next A unless ref $oA;
      print STDERR " +   A == ", $oA->as_text, "\n" if 1 < $self->{'_debug'};
      if (($oA->as_text eq 'next') || ($oA->as_text =~ m!More Web Sites!i))
        {
        my $sURL = $HTTP::URI_CLASS->new_abs($oA->attr('href'), $sCurrURL);
        $self->{_next_url} = $sURL;
        print STDERR " +   FOUND NEXT BUTTON ($sURL)\n" if 1 < $self->{'_debug'};
        last CENTER;
        } # if
      } # foreach
    } # foreach $oCENTER
  # Look for the total result count:
  my @aoFONT = $tree->look_down('_tag', 'font');
 FONT:
  foreach my $oFONT (@aoFONT)
    {
    next FONT unless ref $oFONT;
    print STDERR " +   FONT == ", $oFONT->as_text, "\n" if 1 < $self->{'_debug'};
    if (($oFONT->as_text =~ m!([\d,]+) Web sites were found!i))
      {
      # <FONT FACE=verdana COLOR=#999999 SIZE=-2>&nbsp;&nbsp;<B>3,425</B> Web sites were found in a search of the complete Lycos Web catalog</FONT>
      $i = $1;
      $i =~ s!,!!g;
      $self->approximate_result_count(0+$i);
      last FONT;
      } # if
    } # foreach $oFONT
  $tree->delete;
  return $hits_found;
  } # native_retrieve_some


1;

__END__

URL for GUI query:
http://www.lycos.com/srch/?lpv=1&loc=searchhp&query=thurn
