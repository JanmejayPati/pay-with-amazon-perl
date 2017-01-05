#!/usr/bin/perl

use strict;
use CGI::Simple;
use CGI::Session;
use Digest::MD5; 

my $cgi = new CGI::Simple;
my $session = new CGI::Session($cgi);

$session->param("token",Digest::MD5::md5_base64( rand ));

print $session->header;

my $token = $session->param("token");

my $html = q~<!doctype html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title>Amazon Express Payment</title>
	<script type='text/javascript' src="https://static-na.payments-amazon.com/OffAmazonPayments/us/sandbox/js/Widgets.js"></script>
    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>

    <style>
        label,
        div {
            margin: 10px;
        }
    </style>
</head>
<body>~;
	$html .= qq~<input type="hidden" name="csrf" id="csrf" value="$token">
    <label id="itemname" for="tshirt">Item Name: Long Sleeve Tee</label>
    <div id="amount" value="10">Price: \$10</div>

    <label for="QuantitySelect">Qty:</label>
    <select id="QuantitySelect">
        <option value="1">1</option>
        <option value="2">2</option>
        <option value="3">3</option>
        <option value="4">4</option>
    </select>~;
    $html .= q~<div id="AmazonPayButton"></div>

	<script type="text/javascript">
        OffAmazonPayments.Button("AmazonPayButton", "YOUR_SELLER_ID_HERE", {

            type: "hostedPayment",

            hostedParametersProvider: function(done) {

                $.getJSON("express_signature.pl", {
                    amount: parseInt($("#amount").attr("value")) * parseInt($("#QuantitySelect option:selected").val()),
                    currencyCode: 'USD',
                    sellerNote: $("#itemname").text() + ' QTY: ' + $("#QuantitySelect option:selected").val(),
                    csrf:$("#csrf").val()

                }, function(data) {
                    done(data);
                })
            },
            onError: function(errorCode) {
                console.log(errorCode.getErrorCode() + " " + errorCode.getErrorMessage());
            }
        });
    </script>
</body>
</html>~;

print $html;