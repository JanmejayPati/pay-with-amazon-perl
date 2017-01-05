#!/usr/bin/perl
use strict;
use warnings;
use CGI::Simple;
use CGI::Session;
use JSON;

use vars qw[$merchant_id $lwa_client_id $access_key $secret_key $returnurl];

require 'express.config.pl';

my $cgi = new CGI::Simple;
my $json = new JSON;
my $session = new CGI::Session($cgi);

my %cgi_params = $cgi->Vars;
my %params;

if ($cgi_params{csrf} eq $session->param("token")) {
	
	## use only required params for now

	@params{qw[sellerId returnURL accessKey lwaClientId]} = ( $merchant_id, $returnurl, $access_key, $lwa_client_id );

	$params{amount} = $cgi_params{amount};

	## optional
	foreach my $param_name (qw[sellerNote sellerOrderId currencyCode]) {
		if ( defined( $cgi_params{$param_name} ) && $cgi_params{$param_name} ) {
			$params{$param_name} = $cgi_params{$param_name};
		}
	}

	$params{paymentAction}           = 'AuthorizeAndCapture';
	$params{shippingAddressRequired} = 'false';

	my $sig = amazon_pay_signature( \%params, { secret => $secret_key } );

	$params{signature} = url_encode($sig);

	print $session->header(-type => "application/json", -charset => "utf-8");
	print $json->encode(\%params);
}else{
	$params{error} = 1;
	print $session->header(-type => "application/json", -charset => "utf-8");
	print $json->encode(\%params);
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