# Lycos.pm
# by Wm. L. Scheding and Martin Thurn
# Copyright (C) 1996-1998 by USC/ISI
# $Id: Lycos.pm,v 1.19 2000/09/15 18:19:57 mthurn Exp $

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

$VERSION = '2.12';
$MAINTAINER = 'Martin Thurn <MartinThurn@iname.com>';

use Carp ();
use WWW::Search(qw( generic_option strip_tags unescape_query ));
require WWW::SearchResult;
use URI::Escape;

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

  # During Sites searches, lycos.com returns 10 hits per page no
  # matter what.
  my $DEFAULT_HITS_PER_PAGE = 100;
  $DEFAULT_HITS_PER_PAGE = 20 if 0 < $self->{_debug};
  $self->{'_hits_per_page'} ||= 0;
  $self->{'_hits_per_page'} = $DEFAULT_HITS_PER_PAGE unless 0 < $self->{'_hits_per_page'};

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
  my($response) = $self->http_request('GET', $sCurrURL);
  $self->{response} = $response;
  if (!$response->is_success) 
    {
    return undef;
    }
  
  $self->{'_next_url'} = undef;
  $self->{'_next_to_retrieve'} += $self->{'_hits_per_page'};
  print STDERR " *   got response\n" if $self->{_debug};
  # parse the output
  my ($HEADER, $HITS, $DESC, $COLLECT, $SKIP1, $SKIP2) = qw( HE HI DE CO K1 K2 );
  my $hits_found = 0;
  my $state = $HEADER;
  my $cite = "";
  my $hit;
  my $description = '';
 LINE_OF_INPUT:
  foreach ($self->split_lines($response->content()))
    {
    next LINE_OF_INPUT if m@^$@; # short circuit for blank lines

    print STDERR " * $state ===$_=== " if 2 <= $self->{'_debug'};

    if ($state eq $HEADER && m|^Web\sSites</b></TD>|i)
      {
      # Actual line of input:
      # Web Sites</b></TD>
      $state = $SKIP2;
      }
    elsif ($state eq $SKIP1 && m|^<B>Featured On Lycos</B>$|)
      {
      $state = $SKIP2;
      }
    elsif ($state eq $SKIP2 && m|end vertical partner offers|)
      {
      #                        <!-- end vertical partner offers -->
      $state = $HITS;
      }
    elsif ($state eq $HEADER && m|<b>Web\sPages|i)
      {
      # Actual lines of input are:
      # <B>Web Pages</B>&nbsp;<I>(37054)</I>
      # <b>Web Pages
      # <FONT FACE=verdana COLOR=#999999 SIZE=-2>&nbsp;&nbsp;<B>199,255</B> Web sites were found in 0.1697 seconds during an Advanced Search of All the Web</FONT>
      print STDERR " page list intro\n" if ($self->{_debug});
      if (m=\(([0-9,]+)\)= || m=<B>([0-9,]+)</B>=i)
        {
        my $sCount = $1;
        $sCount =~ s!,!!g;
        $self->approximate_result_count($sCount);
        } # if
      $state = $HITS;
      } # if
    elsif ($state eq $HEADER && m!<B>([,\d]+)</B>\s*Web\ssites?\s(?:were|was)\sfound!i)
      {
      # Actual line of input are:
      # <FONT FACE=verdana COLOR=#999999 SIZE=-2>&nbsp;&nbsp;<B>127</B> Web sites were found in a search of the complete Lycos Web catalog</FONT>
      # <FONT FACE=verdana COLOR=#999999 SIZE=-2>&nbsp;&nbsp;<B>1</B> Web site was found in 0.0502 seconds during an Advanced Search of All the Web</FONT>
      print STDERR " site list intro\n" if ($self->{_debug});
      my $i = $1;
      $i =~ s/,//;
      $self->approximate_result_count($1);
      $state = $HITS;
      } # if

    elsif ($state eq $HITS && m@<LI><A HREF=\"?([^">]+?)\"?><B>\s?(.*?)</A>@i)
      {
      # Actual line of input is:
      # <LI><A HREF="http://www.fortunecity.com/lavendar/python/134/">WISHBONE - A SHORT BIO OF THE GREAT SHOW FOR CHILDREN</A>&nbsp;<BR>
      # <p><b><a href="http://scifireplicas.com/movies/masks.htm">Merchandise Collector Masks - Star Wars</A></b>
      my ($url, $title) = ($1,$2);
      if ($url =~ m/dir\.lycos\.com/)
        {
        print STDERR "skip lycos category name\n" if 2 <= $self->{_debug};
        next LINE_OF_INPUT;
        } # if
      print STDERR "hit url line\n" if 2 <= $self->{_debug};
      if (defined($hit)) 
        {
        push(@{$self->{cache}}, $hit);
        };
      $hit = new WWW::SearchResult;
      $hit->add_url($url);
      $hits_found++;
      $hit->title(strip_tags($title));
      if ($url =~ m=//news\.lycos\.com/=)
        {
        $state = $COLLECT;
        }
      else
        {
        $state = $DESC;
        }
      }
    elsif ($state eq $HITS && (m!Try searching for!i || 
                               m!Second opinion!i || 
                               m!\.doubleclick\.!))
      {
      # Actual line of input is:
      # <CENTER><TABLE BGCOLOR="#FFFFFF" CELLSPACING=0 CELLPADDING=3 BORDER=0><TR><TD ALIGN=MIDDLE><FONT SIZE=-1 FACE=Verdana><a href="http://www.lycos.com/hotbot-redirect.html?query=vjbrooks">Second opinion? Try searching for "<B>vjbrooks</B>" at</a></font></td><TD VALIGN=MIDDLE><a href="http://www.lycos.com/hotbot-redirect.html?query=vjbrooks"><IMG SRC="http://a284.g.akamai.net/f/284/987/12h/lygo.com/ly/p/hb_sr.gif" BORDER=0 WIDTH=100 HEIGHT=29></a></TD></TR></TABLE></CENTER><P>
      print STDERR "no next button\n" if 2 <= $self->{_debug};
      # last LINE_OF_INPUT;
      }

    elsif ($state eq $HITS && m!<P>!i)
      {
      print STDERR " multi-result line, splitting...\n" if 2 <= $self->{_debug};
      # Actual line of input is
      # <LI><FONT FACE=verdana SIZE=-1><a href="http://click.hotbot.com/director.asp?id=1&target=http://www.pitt.edu/%7ethurn/&query=Martin+Thurn&rsource=LCOSW1"><b>Martin</b> <b>Thurn</b>'s Index Page</a> - <b>Martin</b> <b>Thurn</b> Why am I so busy? I am gainfully employed at TASC. I have a family including 3 beautiful children. I am a co-habitant with two immaculate cats. I am the editor of The Star Wars Collector,</FONT><BR><I><FONT FACE=verdana size=-2 COLOR=#999999>http://www.pitt.edu/~<b>thurn</b>/</FONT></I><P></LI><LI><FONT FACE=verdana SIZE=-1><a href="http://click.hotbot.com/director.asp?id=2&target=http://www.posta.suedtirol.com/&query=Martin+Thurn&rsource=LCOSW1">Gasthof Post - St. <b>Martin</b> in <b>Thurn</b>, S. <b>Martin</b> in Badia, Pustertal, Val Pusteria,</a> - Diese Web-Seite verwendet Frames. Frames werden von Ihrem Browser aber nicht unterstutzt.</FONT><BR><I><FONT FACE=verdana size=-2 COLOR=#999999>http://www.posta.suedtirol.com/</FONT></I><P></LI><LI>...
      my @asHits = split /\074[Pp]\076/;
 HIT:
      foreach my $sHit (@asHits)
        {
        # Actual chunk of the line is:
        # <LI><FONT FACE=verdana SIZE=-1><a href="http://click.hotbot.com/director.asp?id=1&target=http://burn.ucsd.edu/%7eresist/prison.html&query=prison&rsource=LCOSW2"><b>Prison</b>, Police, rePression</a></FONT><BR><FONT FACE=verdana size=-2 COLOR=#000000><I>Society  &gt; </I><I> Issues  &gt; </I><I> Human Rights  &gt; </I><FONT FACE="verdana,helvetica,arial" SIZE=-2><A HREF="http://dir.lycos.com/Society/Issues/Human_Rights/Political_Prisoners"><B> Political Prisoners</B></A></FONT></FONT>
        # </LI><LI><FONT FACE=verdana SIZE=-1><a href="http://click.hotbot.com/director.asp?id=9&target=http://www.igc.apc.org/prisons/&query=prison&rsource=LCOSW2"><b>Prison</b> Issues Desk</a></FONT><BR><FONT FACE=verdana size=-2 COLOR=#000000><I>Society  &gt; </I><I> Issues  &gt; </I><I> Human Rights  &gt; </I><FONT FACE="verdana,helvetica,arial" SIZE=-2><A HREF="http://dir.lycos.com/Society/Issues/Human_Rights/Political_Prisoners"><B> Political Prisoners</B></A></FONT></FONT>
        # </LI><LI><FONT FACE=verdana SIZE=-1><a href="http://click.hotbot.com/director.asp?id=10&target=http://www.hrw.org/advocacy/prisons/&query=prison&rsource=LCOSW2">Human Rights Watch <b>Prison</b> Project: <b>Prison</b> Conditions and the Treatment of Prisoners</a> - Information on <b>prison</b> conditions around the world, international human rights standards applicable to prisoners, and <b>prison</b>-related activities of the U.N. and other organizations.</FONT><BR><FONT FACE=verdana size=-2 COLOR=#000000><I>Society  &gt; </I><I> Issues  &gt; </I><I> Crime and Justice  &gt; </I><I> Prisons  &gt; </I><FONT FACE="verdana,helvetica,arial" SIZE=-2><A HREF="http://dir.lycos.com/Society/Issues/Crime_and_Justice/Prisons/Organizations"><B> Organizations</B></A></FONT></FONT>
        print STDERR " +   $state ===$sHit=== " if 2 <= $self->{'_debug'};
        my ($iHit,$iPercent,$iBytes,$sURL,$sTitle,$sDesc,$sDate) = (0,0,0,'','','','');
        $sURL = &strip_tags($1) if $sHit =~ m!target=\"?(.+?)[&\">]!;
        if ($sURL =~ m!\s(>|&gt;)\s!)
          {
          # This link is a Lycos category; we have to get the URL from
          # somewhere else in the line:
          $sURL = &uri_unescape($1) if $sHit =~ m!target=(.+?)&!i;
          }
        $sTitle = &strip_tags($1) if $sHit =~ m!LCOSW\d+\">(.+?)<BR>!i;
        $sTitle = &strip_tags($1) if $sHit =~ m!LCOSW\d+\">(.+?)</a>\s-\s!i;
        my $sLoc = &strip_tags($1) if $sHit =~ m!<BR>(.+?)</FONT>!;
        $sDesc = &strip_tags($1) if $sHit =~ m!</a>\s-\s(.+?)</FONT>!;
        if ($sURL ne '')
          {
          if (ref($hit))
            {
            push(@{$self->{cache}}, $hit);
            } # if
          $hit = new WWW::SearchResult;
          $hit->add_url(uri_unescape($sURL));
          $hit->title($sTitle) if $sTitle ne '';
          $hit->description($sDesc) if $sDesc ne '';
          $hit->location($sLoc) if $sLoc ne '';
          $hit->score($iPercent) if 0 < $iPercent;
          $hit->size($iBytes) if 0 < $iBytes;
          $hit->change_date($sDate) if $sDate ne '';
          $self->{'_num_hits'}++;
          $hits_found++;
          print STDERR " OK\n" if 2 <= $self->{_debug};
          } # if $URL
        else
          {
          print STDERR " CANNOT FIND URL\n" if 2 <= $self->{_debug};
          }
        } # foreach
      }

    # -------------------------------------------------------------------------
    # Modifications: 12/26/99 by dbradford@bdctechnologies.com
    #	Fixed reg expression to handle the font tags Lycos has added to output.
    #	Old reg expression wouldn't grab the title, new one fixes this of course.
    #	I have kept the old and new below to show the difference. You may cut out this
    #	code if you so desire.
    # Old: 
    #       (m@^(?:<LI>|\s)?<a href=\"?([^">]+?)\"?\>(.*?)</a>\s-\s(.*)$@i ||
    #        m@<LI><a href=\"?([^">]+?)\"?\>(.*?)</A>&nbsp;\<BR\>(.*)$@i))
    # New: 
    #       (m@^(?:<LI>|\s)?.*?<a href=\"?([^">]+?)\"?\>(.*?)</a>\s-\s(.*)$@i ||
    #        m@<LI>.*?<a href=\"?([^">]+?)\"?\>(.*?)</A>&nbsp;\<BR\>(.*)$@i))
    # -------------------------------------------------------------------------
    
    elsif ($state eq $HITS && 
           (m@^(?:<LI>|\s)?.*?<a href=\"?([^">]+?)\"?\>(.*?)</a>\s-\s(.*?)</FONT>@i ||
            m@<LI>.*?<a href=\"?([^">]+?)\"?\>(.*?)</A>&nbsp;\<BR\>(.*?)</FONT>@i))
      {
      # Actual line of input is:
      # <li><a href=http://www.cds.com/>CD Solutions Inc. CD-ROM, Replication, and Duplication page</a> - <font size=-1>CD Solutions makes CD-ROM production easy</font> 
      #  <a href="http://www.toysrgus.com">The <b>Star</b> <b>Wars</b> Collectors Archive</a> - <font size=-1>An archive of <b>Star</b> <b>Wars</b> Collectibles.</font> <font size=1>&nbsp;<br><br></font>
      # <a href="http://www.madal.com">Wholesale Only! Pokemon, Magic, <b>Star</b> <b>Wars</b>, <b>Star</b> Trek.  Sales to Qualified retail stores only!</a> - <font size=-1>Wholesale Sales to qualified retail outlets only. We are authorized distributors for Wizards of the Coast, Decipher and most other trading card game companies.  We have Pokemon.</font> <font size=1>&nbsp;<br><br></font>
      print STDERR "hit url+desc line\n" if 2 <= $self->{_debug};
      my ($sURL, $sTitle, $sDesc) = ($1,$2,$3);
      $sURL = unescape_query($1) if $sURL =~ m/target=(.+?)&/i;
      if (defined($hit)) 
        {
        push(@{$self->{cache}}, $hit);
        }
      $hit = new WWW::SearchResult;
      $hit->add_url($sURL);
      $hits_found++;
      $hit->title(strip_tags($sTitle));
      $hit->description(strip_tags($sDesc));
      }

    elsif ($state eq $COLLECT && m=^(.*?)<br>=i)
      {
      print STDERR "end of description collection\n" if 2 <= $self->{_debug};
      $description .= $1;
      $hit->description(strip_tags($description));
      $description = '';
      $state = $HITS;
      }
    elsif ($state eq $COLLECT)
      {
      print STDERR "description collection\n" if 2 <= $self->{_debug};
      $description .= "$_ ";
      }

    elsif ($state eq $DESC && m=^<BR>$=)
      {
      # Actual line of input is:
      # <BR>
      print STDERR "lone BR line\n" if 2 <= $self->{_debug};
      # Do not change state; try to get the description from the next line
      }
    elsif ($state eq $DESC && m=^<TR><TD>$=)
      {
      # Actual line of input is:
      # <TR><TD>
      print STDERR "lone TR TD line\n" if 2 <= $self->{_debug};
      # This item has no description.
      $state = $HITS;
      }
    elsif ($state eq $DESC && m=^(.+)<BR>=i)
      {
      # Actual line of input is:
      # Star Wars logo &nbsp; Merchandise Collector Masks - Star Wars &nbsp; Emperor Palpatine Greedo Yoda Emperor Palpatine Gre<BR>http://scifireplicas.com/movies/masks.htm
      print STDERR "description line\n" if 2 <= $self->{_debug};
      my $sDescription = $1;
      $hit->description(strip_tags($sDescription)) if defined($hit);
      $state = $HITS;
      }

    elsif ($state eq $HITS && m!<A\sHREF=\"?([^">]+)\"?\><B>(?:next|More Web Sites)</B>!i)
      {
      # Actual line of input is:
      # [ 9,469 <a href="/srch/more.html?lpv=1&type=websites&loc=mlink_w&l=0&y=9479&c=0&o=0&s=9479&cw=1&fw=9478&pn=&qc=&fg=&xs=FW&ss=961095406|2&page=1&query=thurn&first=11"><B>More Web Sites</B></a> about <B>thurn</B> ]</FONT>
      print STDERR "next line\n" if 2 <= $self->{_debug};
      # There is a "next" button on this page, therefore there are
      # indeed more results for us to go after next time.
      my $sURL = $1;
      $self->{'_next_to_retrieve'} = $1 if $sURL =~ m/first=(\d+)/;
      $self->{'_next_url'} = URI->new_abs($sURL, $sCurrURL);
      print STDERR " * next URL is ", $self->{'_next_url'}, "\n" if 2 <= $self->{_debug};
      # print STDERR " * next URL is ", $self->{'_next_url'}, "\n";
      last LINE_OF_INPUT;
      }
    else
      {
      print STDERR "didn't match\n" if 2 <= $self->{_debug};
      }
    } # foreach

  if (defined($hit)) 
    {
    push(@{$self->{cache}}, $hit);
    } # if
  
  # Sometimes, the result page for a Lycos::Sites search has a DEAD
  # next link.  Here is a hack to create our own _next_url based on
  # what WE know about the search so far:
  if (ref($self) =~ m/::Sites/ &&
      $self->{'_next_to_retrieve'} <= $self->approximate_result_count
     )
    {
    $self->{_options}->{'first'} = $self->{'_next_to_retrieve'};
    $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $self->hash_to_cgi_string($self->{_options});
    }

  return $hits_found;
  } # native_retrieve_some


1;

__END__

URL for GUI query:
http://www.lycos.com/srch/?lpv=1&loc=searchhp&query=thurn
