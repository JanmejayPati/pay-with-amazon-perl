#!/usr/bin/perl
use strict;
use warnings;
use CGI::Simple;
use CGI::Session;
use URI;

use vars qw[$merchant_id $lwa_client_id $access_key $secret_key $returnurl];

require 'express.config.pl';

my $cgi = new CGI::Simple;
my $session = new CGI::Session($cgi);

my %cgi_params = $cgi->Vars;

my $resultCode			= $cgi_params{resultCode};
my $orderReferenceId    = $cgi_params{orderReferenceId};
my $sellerId			= $cgi_params{sellerId};
my $accessKey			= $cgi_params{accessKey};
my $amount				= $cgi_params{amount};
my $currencyCode		= $cgi_params{currencyCode};
my $paymentAction		= $cgi_params{paymentAction};
my $signature			= url_decode($cgi_params{signature});
my $failureCode			= $cgi_params{failureCode};

delete($cgi_params{signature});
$session->param("token", undef);

my $parse_uri = URI->new($returnurl);

my $generated_signature = amazon_pay_signature( \%cgi_params, { secret => $secret_key, host => $parse_uri->host, path => $parse_uri->path, method => 'GET' } );

print $session->header();

if ($signature eq $generated_signature && $resultCode eq  'Success') {
	print "All OK!! Do your next checkout process... \n";
}else{
	print "Your transaction was not successful and you have not been charged. \n";
}

sub amazon_pay_signature {
    my $params = shift;
    my $args = shift || {};

	require Digest::SHA;
	Digest::SHA->import(qw(hmac_sha256_base64));

    ## order the keys
    my @keys_order = sort { $a cmp $b } keys %{$params};

    ## query string format
    my $qs = join( '&', map { $_ . '=' . url_encode( $params->{$_} ) } @keys_order );

	## set defaults
	$args->{method} ||= 'POST';
	$args->{host} ||= 'payments.amazon.com';
	$args->{path} ||= '/';

    ## build string for signature
    my $string_to_sign = join( "\n", @{$args}{qw[method host path]}, $qs );

    my $digestb64 = hmac_sha256_base64( $string_to_sign, $args->{secret} );

    ## add padding if required
    while ( length($digestb64) % 4 ) {
        $digestb64 .= '=';
    }

    return $digestb64;
}
sub url_encode {
    my $str  = shift;
    $str =~ s/([^0-9A-Za-z_.~-])/sprintf('%%%02X',ord($1))/eg;
    return $str;
}
sub url_decode {
    my $str  = shift;
    $str =~ s/%([A-Fa-f\d]{2})/chr(hex($1))/eg;
    return $str;
}