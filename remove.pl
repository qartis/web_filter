#!/usr/bin/perl -w
use HTTP::Proxy qw( :log );
use HTTP::Proxy::BodyFilter::complete;
use HTTP::Proxy::BodyFilter::simple;
use XML::LibXML;
use Data::Dumper;
use strict;

my %changes = (
  'www.slackware.com' => ["/html/body/center/table/tr[2]/td[1]","/html/body/center/table/tr/td/table/tr/td[2]/table/tr/td/table/tr/td/a"]
);

my $proxy = HTTP::Proxy->new(@ARGV);

$proxy->push_filter(
    response => HTTP::Proxy::BodyFilter::complete->new(),
    response => HTTP::Proxy::BodyFilter::simple->new(
      sub {
        my ( $self, $dataref, $message, $protocol, $buffer ) = @_;
        next if ! $$dataref;

        my $host = $message->request->uri->host;

        next if ! $changes{$host};

        my $parser = XML::LibXML->new();
        $parser->recover(1);
        $parser->no_network(1);
        my $doc = $parser->parse_html_string($$dataref);
        my $context = XML::LibXML::XPathContext->new($doc);
        my @hitlist = ();

        for my $xpath (@{$changes{$host}}){
          push(@hitlist,$context->findnodes($xpath));
        }

        for my $node (@hitlist){
          my $parent = $node->parentNode;
          $parent->removeChild($node);
        }
        $$dataref = $doc->toString();
      }
    )
);

$proxy->start;
