#!/usr/bin/perl

use warnings;
use CGI;
use DBI;
use Number::Format 'format_number';
use List::Util qw/sum/;
use File::Copy;
use File::Path;

#get variables from the html form
my $query = new CGI;
my $a = $query->param("a");
my $access = $query->param("access");
my $wallet = $query->param("wallet");
my $pass = $query->param("pass");

#this is for testing so I can see outputs in the browser
#$|=1;            # Flush immediately.
#print "Content-Type: text/plain\n\n";

#split incoming training vars
my @a_array = split/\./,$a;

#set a to choice of frequency
$a = $a_array[0];

#print $a_array[1];

#a little switcharoo depending on how they came into this page
if ($wallet eq ''){
$wallet = $a_array[1];
}

if ($a_array[1] eq ''){
$a_array[1] = $wallet;
}

#declare the var
my $html = ();

#checks to see if logged in or not and feeds them a login page
if ($wallet eq '' && $a_array[1] eq ''){

$html = ();

$html = qq{Content-Type: text/html

<link rel="stylesheet" type="text/css" href="https://my.ergoport.dev/tosipayroll/tosipay.css">

<body>
<div>
<form class="form-style-7" ACTION="/cgi-bin/tosipayroll/tp_payroll_view.pl?a=$a"  METHOD="post" enctype="multipart/form-data">
<form ACTION="/cgi-bin/tosipayroll/tp_payroll_view.pl?a=$a" METHOD="post" enctype="multipart/form-data">
    <h1>Ergo Payroll - Dashboard</h1>
<div>
<br>
<br>
<body>
<br>
</body>
<body style="  background-image: linear-gradient(lightblue, white)">
<li>
<font size="+2">Login to Payroll/Process</font size="+2">
<br>
<br>
<label for="wallet"><b>Wallet:</b></label>
<input type="text" name="wallet" maxlength="200">
<br>
<label for="pass"><b>Password:</b></label>
<input type="password" name="pass" maxlength="50">
<input type="hidden" value="$a" name="a" maxlength="100">
<br>
</li>
<br>

        <INPUT TYPE="submit" NAME="Submit" VALUE="Go to Payroll/Process">
<br>
<br>
</form>
</div>
};

#print login page
print $html;
exit;

}


#this is for testing so I can see outputs in the browser
#$|=1;            # Flush immediately.
#print "Content-Type: text/plain\n\n";

#time calculation
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
my $year = 1900 + $yearOffset;
my $theTime = "$months[$month] $dayOfMonth, $year - $weekDays[$dayOfWeek] $hour:$minute";


##declcare a few vars
my $html2 = '';
my $html25 = '';
my $html26 = '';
my $html3 = '';
my $total_overall_neta = ();
my $total_overall_ergopad = ();
my $total_overall_erg = ();
my $total_overall_comet = ();
my $total_overall_Paideia = ();
my $total_overall_MiGoreng = ();

### first part of the html, top of page
my $html = qq{Content-Type: text/html

<link rel="stylesheet" type="text/css" href="https://my.ergoport.dev/tosipayroll/tosipay.css">

<body>
<div>
<form class="form-style-7" ACTION="/cgi-bin/tosipayroll/tp_process.pl" METHOD="post" enctype="multipart/form-data">
<form ACTION="/cgi-bin/tosipayroll/tp_process.pl" METHOD="post" enctype="multipart/form-data">
    <h1>Ergo Payroll - View/Push Payment</h1>
<div>
<br>
<br>
<body>
<br>
<a href="https://my.ergoport.dev/tosipayroll/tp_upload.html">Upload More Base Data</a>
 | <a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_dashboard.pl">Individual Edit Dashboard</a>
<br><p>
</body>
<a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_payroll_view.pl?a=all.$a_array[1]">All Frequency's</a> | <a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_payroll_view.pl?a=12">12</a> | <a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_payroll_view.pl?a=24.$a_array[1]">24</a> | <a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_payroll_view.pl?a=52.$a_array[1]">52</a>
<br><p>
<body style="  background-image: linear-gradient(lightblue, white)">
<li>
<font size="+2">Payroll View</font size="+2">
<br>
<br>
};

print $html;

######## mysql initial base data and other vars #########

my $sql = ();
my $sth = ();
my $sql_lu = ();
my $sth_lu = ();
my $email_to_wallet = ();
my $token_name = "UNKNOWN";
my $total_i_token_price_12 = ();
my $total_USD_token_price_12 = ();
my $total_USD_token_price_24 = ();
my $total_USD_token_price_52 = ();
my $total_i_token_price_24 = ();
my $total_i_token_price_52 = ();
my $total_USD_token_price_total = ();
my $frequency = ();


#passing the account var to the script
if ($a ne ''){
$frequency = "and employee_pay_frequency='$a'";
}

#this gets the mysql password from a file so we don't have to store it in the script
open my $fh, '<', '/usr/lib/cgi-bin/sql.txt' or die "Can't open file $!";
$password = do { local $/; <$fh> };

#remove white spaces in the file just in case
$password =~ s/^\s+//;
$password =~ s/\s+$//;

#define mysql connection details
my $db="tosipayroll";
my $host="localhost";
my $user="root";


#connect to MySQL database
my $dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host",
  $user,
  $password)
  or die "Can't connect to database: $DBI::errstr\n";

##################


### password access check ######
my $sql_access = "select * from employer where company_wallet_id='$wallet';";

#prepare the query
my $sth_access = $dbh->prepare($sql_access);

#execute the query
$sth_access->execute();

#put it into an array
$" = "<br>";
while (my @row_access = $sth_access->fetchrow_array( ) )  {
  push(@array_access, @row_access);

};

#i forgot why i did this, will remove once password system is in place
$access = @array_access[6];

#set user to correct id in the mysql table if they exist
if ($array_access[2] eq $wallet && $array_access[6] ne ''){
$access = $array_access[6];
}
#tell the user their pasword or id was wrong
else {
### first part of the html
$html = qq{Content-Type: text/html

<link rel="stylesheet" type="text/css" href="https://my.ergoport.dev/tosipayroll/tosipay.css">

<body>
<div>
<form class="form-style-7" enctype="multipart/form-data">
<form ACTION="/cgi-bin/tosipayroll/tp_newuser.pl" METHOD="post" enctype="multipart/form-data">
    <h1>Ergo Payroll - Import</h1>
<div>
<br>
<br>
<body>
<br>
</body>
<body style="  background-image: linear-gradient(lightblue, white)">
<li>
<font size="+2">OOPS!</font size="+2"><br><br>
<br>
};

print $html;




$html2 = "Wrong Password or Wallet! Hit back and try again!";
print $html2;

$html3  = qq{
<br>
</li>
        <INPUT TYPE="hidden" NAME="Submit" type="HIDDEN" VALUE="Create Account">

</form>
</div>



};

print $html3;
exit;

}

#declare and set vars for big loop through multi array
$n = '9';
$n1 = '10';
$n2 = '11';
$n3 = '12';
$n4 = '13';
$n5 = '14';
$n6 = '15';
$n7 = '16';
$n8 = '17';

#start at employee 1
my $employee_number = '1';

#start the loop to get all the employees under that employer
while (@list[$n] ne ''){

#declare mysql statment 
$sql_lu = "select id from employee where company_wallet_id='$array_access[0]' and e_company_wallet_id='$list[$n2]';";

#prepare the query
$sth_lu = $dbh->prepare($sql_lu);

#execute the query
$sth_lu->execute();

## Retrieve the results of a row of data and put in an array
$" = "<br>";
while (my @row_lu = $sth_lu->fetchrow_array( ) )  {
  push(@array_lu, @row_lu);

};

#step increase the ints for another loop
$n = $n + 9;
$n1 = $n1 + 9;
$n2 = $n2 + 9;
$n3 = $n3 + 9;
$n4 = $n4 + 9;
$n5 = $n5 + 9;
$n6 = $n6 + 9;
$n7 = $n7 + 9;
$n8 = $n8 + 9;
$employee_number = $employee_number + 1;
@array_lu = ();
$email_to_wallet = ();

}


#header for pure token payout
my $html254 = "<br><br>****************<br><b><font size=\"+1\">Employees Paid In Pure Token Count</font size=\"+1\"></b><br><br>";
print $html254;


###### get the counts of the import for data display
my $sql_counts = "select employee_token_id, 
SUM(employee_token_count), 
COUNT(company_wallet_id), 
COUNT(employee_pay_frequency), 
employee_pay_frequency 
from employee 
where employee_token_count IS NOT NULL 
and employee_usd_amount=''
$frequency
and company_wallet_id='$array_access[2]' group by employee_token_id, employee_pay_frequency order by employee_pay_frequency;";

#prepare the query
my $sth_counts = $dbh->prepare($sql_counts);

#execute the query
$sth_counts->execute();


## Retrieve the results of a row of data and put in an array
$" = "<br>";
while (my @row_counts = $sth_counts->fetchrow_array( ) )  {
  push(@array_counts, @row_counts);

####token ID define
$token_name = "UNKNOWN";

if ($array_counts[0] eq "0cd8c9f416e5b1ca9f986a7f10a84191dfb85941619e49e53c0dc30ebf83324b"){
$token_name = "COMET";
}

if ($array_counts[0] eq "0779ec04f2fae64e87418a1ad917639d4668f78484f45df962b0dec14a2591d2"){
$token_name = "MiGoreng";
}

if ($array_counts[0] eq "472c3d4ecaa08fb7392ff041ee2e6af75f4a558810a74b28600549d5392810e8"){
$token_name = "NETA";
}

if ($array_counts[0] eq "1fd6e032e8476c4aa54c18c1a308dce83940e8f4a28f576440513ed7326ad489"){
$token_name = "Paideia";
}

if ($array_counts[0] eq "d71693c49a84fbbecd4908c94813b46514b18b67a99952dc1e6e4791556de413"){
$token_name = "Ergopad";
}

if ($array_counts[0] eq "00b1e236b60b95c2c6f8007a9d89bc460fc9e78f98b09faec9449007b40bccf3"){
$token_name = "EGIO";
}

if ($array_counts[0] eq "007fd64d1ee54d78dd269c8930a38286caa28d3f29d27cadcb796418ab15c283"){
$token_name = "EXLE";
}

if ($array_counts[0] eq "e8b20745ee9d18817305f32eb21015831a48f02d40980de6e849f886dca7f807"){
$token_name = "FLUX";
}


### yup, lets price check these against my.ergoport.dev API database

#define mysql connection details
my $db2="ergoport";

#connect to MySQL database
my $dbh_price   = DBI->connect ("DBI:mysql:database=$db2:host=$host",
  $user,
  $password)
  or die "Can't connect to database: $DBI::errstr\n";

my $sql_price = "select $token_name from pricedata;";

#prepare the query
my $sth_price = $dbh_price->prepare($sql_price);

#execute the query
$sth_price->execute();


## Retrieve the results of a row of data and put in an array
$" = "<br>";
while (my @row_price = $sth_price->fetchrow_array( ) )  {
  push(@array_price, @row_price);
}


### once a month
#the below will take the count and current price and figure out how much USD it is
if (@array_counts[4] eq '12'){
$total_i_token_price_12 = $array_counts[1] * $array_price[0];
$total_USD_token_price_12 = $total_USD_token_price_12 + $total_i_token_price_12;
$total_i_token_price_12 = sprintf("%.2f", $total_i_token_price_12);

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts[4]<br>
<b>Sum Per Period: </b>@array_counts[1] <br>
<b>Sum of Amount in USD: </b> \$$total_i_token_price_12 <br>
<b>Received by \# of employees:</b> @array_counts[2] <br>";
print $html25;
if ($token_name eq 'NETA'){
$total_overall_neta = @array_counts[1] + $total_overall_neta;
}
if ($token_name eq 'Ergopad'){
$total_overall_Ergopad = @array_counts[1] + $total_overall_Ergopad;
}
if ($token_name eq 'ERG'){
$total_overall_erg = @array_counts[1] + $total_overall_erg;
}
if ($token_name eq 'COMET'){
$total_overall_comet = @array_counts[1] + $total_overall_comet;
}
if ($token_name eq 'Paideia'){
$total_overall_Paideia = @array_counts[1] + $total_overall_Paideia;
}
if ($token_name eq 'MiGoreng'){
$total_overall_MiGoreng = @array_counts[1] + $total_overall_MiGoreng;
}
}

####TWICE A MONTH
if (@array_counts[4] eq '24'){
$total_i_token_price_24 = ($array_counts[1] * $array_price[0]);
$total_USD_token_price_24 = $total_USD_token_price_24 + $total_i_token_price_24;
#$total_i_token_price_24 = $total_i_token_price_24 * 2;
$total_i_token_price_24 = $total_i_token_price_24;
$total_i_token_price_24 = sprintf("%.2f", $total_i_token_price_24);
@array_counts[1] = @array_counts[1] * 2;

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts[4]<br>
<b>Sum Per Period: </b>@array_counts[1] <br>
<b>Sum of Amount in USD: </b> \$$total_i_token_price_24 <br>
<b>Received by \# of employees:</b> @array_counts[2] <br>";
print $html25;
if ($token_name eq 'NETA'){
$total_overall_neta = @array_counts[1] + $total_overall_neta;
}
if ($token_name eq 'Ergopad'){
$total_overall_Ergopad = @array_counts[1] + $total_overall_Ergopad;
}
if ($token_name eq 'ERG'){
$total_overall_erg = @array_counts[1] + $total_overall_erg;
}
if ($token_name eq 'COMET'){
$total_overall_comet = @array_counts[1] + $total_overall_comet;
}
if ($token_name eq 'Paideia'){
$total_overall_Paideia = @array_counts[1] + $total_overall_Paideia;
}
if ($token_name eq 'MiGoreng'){
$total_overall_MiGoreng = @array_counts[1] + $total_overall_MiGoreng;
}
}

######every week
if (@array_counts[4] eq '52'){
$total_i_token_price_52 = ($array_counts[1] * $array_price[0]);
$total_USD_token_price_52 = $total_USD_token_price_52 + $total_i_token_price_52;
#$total_i_token_price_52 = $total_i_token_price_52 * 4;
$total_i_token_price_52 = $total_i_token_price_52;
$total_i_token_price_52 = sprintf("%.2f", $total_i_token_price_52);
@array_counts[1] = @array_counts[1] * 4;

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts[4]<br>
<b>Sum Per Period: </b>@array_counts[1] <br>
<b> Sum of Amount in USD: </b> \$$total_i_token_price_52 <br>
<b>Received by \# of employees:</b> @array_counts[2] <br>";
print $html25;
if ($token_name eq 'NETA'){
$total_overall_neta = @array_counts[1] + $total_overall_neta;
}
if ($token_name eq 'Ergopad'){
$total_overall_Ergopad = @array_counts[1] + $total_overall_Ergopad;
}
if ($token_name eq 'ERG'){
$total_overall_erg = @array_counts[1] + $total_overall_erg;
}
if ($token_name eq 'COMET'){
$total_overall_comet = @array_counts[1] + $total_overall_comet;
}
if ($token_name eq 'Paideia'){
$total_overall_Paideia = @array_counts[1] + $total_overall_Paideia;
}
if ($token_name eq 'MiGoreng'){
$total_overall_MiGoreng = @array_counts[1] + $total_overall_MiGoreng;
}
}

@array_price = ();
@array_counts = ();
};


#second part of calulations but with USD to tokens, repeat of above but somewhat the opposite way
my $html255 = "<br><br>****************<br><b><font size=\"+1\">Employees Paid In USD Equivalent</font size=\"+1\"></b><br><br>";
print $html255;


###### get the counts of the import for data display
my $sql_counts_usd = "select employee_token_id,
SUM(employee_usd_amount), 
COUNT(company_wallet_id), 
COUNT(employee_pay_frequency), 
employee_pay_frequency
from employee where 
employee_token_count='' 
and employee_usd_amount IS NOT NULL
$frequency 
and company_wallet_id='$array_access[2]' 
group by employee_token_id,employee_pay_frequency order by employee_pay_frequency;";

#prepare the query
my $sth_counts_usd = $dbh->prepare($sql_counts_usd);

#execute the query
$sth_counts_usd->execute();


## Retrieve the results of a row of data and put in an array
$" = "<br>";
while (my @row_counts_usd = $sth_counts_usd->fetchrow_array( ) )  {
  push(@array_counts_usd, @row_counts_usd);

####token ID define
$token_name = "UNKNOWN";

if ($array_counts_usd[0] eq "0cd8c9f416e5b1ca9f986a7f10a84191dfb85941619e49e53c0dc30ebf83324b"){
$token_name = "COMET";
}

if ($array_counts_usd[0] eq "0779ec04f2fae64e87418a1ad917639d4668f78484f45df962b0dec14a2591d2"){
$token_name = "MiGoreng";
}

if ($array_counts_usd[0] eq "472c3d4ecaa08fb7392ff041ee2e6af75f4a558810a74b28600549d5392810e8"){
$token_name = "NETA";
}

if ($array_counts_usd[0] eq "1fd6e032e8476c4aa54c18c1a308dce83940e8f4a28f576440513ed7326ad489"){
$token_name = "Paideia";
}

if ($array_counts_usd[0] eq "d71693c49a84fbbecd4908c94813b46514b18b67a99952dc1e6e4791556de413"){
$token_name = "Ergopad";
}

if ($array_counts_usd[0] eq "00b1e236b60b95c2c6f8007a9d89bc460fc9e78f98b09faec9449007b40bccf3"){
$token_name = "EGIO";
}

if ($array_counts_usd[0] eq "007fd64d1ee54d78dd269c8930a38286caa28d3f29d27cadcb796418ab15c283"){
$token_name = "EXLE";
}

if ($array_counts_usd[0] eq "e8b20745ee9d18817305f32eb21015831a48f02d40980de6e849f886dca7f807"){
$token_name = "FLUX";
}


### yup, lets price check this again from my.ergoport.dev api database

#define mysql connection details
$db2="ergoport";

#connect to MySQL database
 $dbh_price   = DBI->connect ("DBI:mysql:database=$db2:host=$host",
  $user,
  $password)
  or die "Can't connect to database: $DBI::errstr\n";

$sql_price = "select $token_name from pricedata;";

#prepare the query
$sth_price = $dbh_price->prepare($sql_price);

#execute the query
$sth_price->execute();

## Retrieve the results of a row of data and put in an array
$" = "<br>";
while (@row_price = $sth_price->fetchrow_array( ) )  {
  push(@array_price, @row_price);
}


### once a month
if (@array_counts_usd[4] eq '12'){
$total_i_token_price_12 = $array_counts_usd[1] / $array_price[0];
$total_USD_token_price_12 = $total_USD_token_price_12 + @array_counts_usd[1];
$total_i_token_price_12 = sprintf("%.2f", $total_i_token_price_12);

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts_usd[4]<br>
<b>Sum of Tokens Per Period: </b>$total_i_token_price_12<br>
<b> Sum of Amount in USD: </b> \$@array_counts_usd[1] <br>
<b>Received by \# of employees:</b> @array_counts_usd[2] <br>";
print $html25;
if ($token_name eq 'NETA'){
$total_overall_neta = $total_i_token_price_12 + $total_overall_neta;
}
if ($token_name eq 'Ergopad'){
$total_overall_Ergopad = $total_i_token_price_12 + $total_overall_Ergopad;
}
if ($token_name eq 'ERG'){
$total_overall_erg = $total_i_token_price_12 + $total_overall_erg;
}
if ($token_name eq 'COMET'){
$total_overall_comet = $total_i_token_price_12 + $total_overall_comet;
}
if ($token_name eq 'Paideia'){
$total_overall_Paideia = $total_i_token_price_12 + $total_overall_Paideia;
}
if ($token_name eq 'MiGoreng'){
$total_overall_MiGoreng = $total_i_token_price_12 + $total_overall_MiGoreng;
}
}

####TWICE A MONTH
if (@array_counts_usd[4] eq '24'){
#$total_i_token_price_24 = ($array_counts_usd[1] / $array_price[0]) * 2;
$total_i_token_price_24 = ($array_counts_usd[1] / $array_price[0]);
$total_USD_token_price_24 = ($total_USD_token_price_24 + @array_counts_usd[1]);
$total_i_token_price_24 = sprintf("%.2f", $total_i_token_price_24);
@array_counts_usd[1] = @array_counts_usd[1] * 2;

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts_usd[4]<br>
<b>Sum of Tokens Per Period: </b>$total_i_token_price_24<br>
<b> Sum of Amount in USD: </b> \$@array_counts_usd[1] <br>
<b>Received by \# of employees:</b> @array_counts_usd[2] <br>";
print $html25;
if ($token_name eq 'NETA'){
$total_overall_neta = $total_i_token_price_24 + $total_overall_neta;
}
if ($token_name eq 'Ergopad'){
$total_overall_Ergopad = $total_i_token_price_24 + $total_overall_Ergopad;
}
if ($token_name eq 'ERG'){
$total_overall_erg = $total_i_token_price_24 + $total_overall_erg;
}
if ($token_name eq 'COMET'){
$total_overall_comet = $total_i_token_price_24 + $total_overall_comet;
}
if ($token_name eq 'Paideia'){
$total_overall_Paideia = $total_i_token_price_24 + $total_overall_Paideia;
}
if ($token_name eq 'MiGoreng'){
$total_overall_MiGoreng = $total_i_token_price_24 + $total_overall_MiGoreng;
}
}

######every week
if (@array_counts_usd[4] eq '52'){
#$total_i_token_price_52 = ($array_counts_usd[1] / $array_price[0]) * 4;
$total_i_token_price_52 = ($array_counts_usd[1] / $array_price[0]);
$total_USD_token_price_52 = ($total_USD_token_price_52 + @array_counts_usd[1]);
$total_i_token_price_52 = sprintf("%.2f", $total_i_token_price_52);
@array_counts_usd[1] = @array_counts_usd[1] * 4;

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts_usd[4]<br>
<b>Sum of Tokens Per Period: </b>$total_i_token_price_52<br>
<b> Sum of Amount in USD: </b> \$@array_counts_usd[1] <br>
<b>Received by \# of employees:</b> @array_counts_usd[2] <br>";
print $html25;
if ($token_name eq 'NETA'){
$total_overall_neta = $total_i_token_price_52 + $total_overall_neta;
}
if ($token_name eq 'Ergopad'){
$total_overall_Ergopad = $total_i_token_price_52 + $total_overall_Ergopad;
}
if ($token_name eq 'ERG'){
$total_overall_erg = $total_i_token_price_52 + $total_overall_erg;
}
if ($token_name eq 'COMET'){
$total_overall_comet = $total_i_token_price_52 + $total_overall_comet;
}
if ($token_name eq 'Paideia'){
$total_overall_Paideia = $total_i_token_price_52 + $total_overall_Paideia;
}
if ($token_name eq 'MiGoreng'){
$total_overall_MiGoreng = $total_i_token_price_52 + $total_overall_MiGoreng;
}
}

@array_price = ();
@array_counts_usd = ();
};


#let's show how much it will be in total
$total_USD_token_price_total = $total_USD_token_price_12 + $total_USD_token_price_24 + $total_USD_token_price_52;

#getting the frequency from the submit button and cleaning it up
my $frequency_clipped = $frequency;
$frequency_clipped =~ s/and employee_pay_frequency='//;
$frequency_clipped =~ s/'//;

###get the number of employees that were updated/added
my $sql_ecounts = "select count(company_wallet_id) from employee where company_wallet_id='$array_access[2]' $frequency;";

#prepare the query
my $sth_ecounts = $dbh->prepare($sql_ecounts);

#execute the query
$sth_ecounts->execute();

#this code sets the number to 2 decimal points
$total_USD_token_price_total = sprintf("%.2f", $total_USD_token_price_total);

## Retrieve the results of a row of data and put in an array
$" = "<br>";
while (my @row_ecounts = $sth_ecounts->fetchrow_array( ) )  {
  push(@array_ecounts, @row_ecounts);

#print some summary data for botom of page
$html26 = "<br><br><b>Total Employees:</b> @array_ecounts[0]<br>
<br>
<br>
****************<br><b><font size=\"+1\">
<b>Total Cost in USD for known coins/tokens for frequency $frequency_clipped:</b> \$$total_USD_token_price_total
</b></font size=\"+1\">
<br>
<br>
<b>You need this many tokens in the bank:</b><br>
<b>ERG:</b><br>
<b>Neta:</b> $total_overall_neta<br>
<b>Ergopad:</b> $total_overall_Ergopad<br>
<b>Comet:</b> $total_overall_comet<br>
<b>Paideia:</b> $total_overall_Paideia<br>
<b>MiGoreng:</b> $total_overall_MiGoreng<br>	
<br>
<br>
<br>
";

print $html26;

#clear the array for the loop
@array_counts = ();
};



# allow the user to activate certian pay frequencies
$html3  = qq{

<br>
<br>
<li>
<br>
<label><b>Activate Frequency:</b></label>
<br>
<INPUT TYPE="CheckBox" VALUE="12" NAME="v12">12&nbsp
<INPUT TYPE="CheckBox" VALUE="24" NAME="v24">24&nbsp
<INPUT TYPE="CheckBox" VALUE="52" NAME="v52">52&nbsp
<br><br><br>
<label><b>Deactivate Frequency:</b></label>
<br>
<INPUT TYPE="CheckBox" VALUE="12d" NAME="v12d">12&nbsp
<INPUT TYPE="CheckBox" VALUE="24d" NAME="v24d">24&nbsp
<INPUT TYPE="CheckBox" VALUE="52d" NAME="v52d">52&nbsp
<br><br><br>
<label for="wallet"><b>Wallet:</b></label>
<input type="text" name="wallet" maxlength="200">
<br>
<label for="pass"><b>Password:</b></label>
<input type="password" name="pass" maxlength="50">
<input type="hidden" value="$a" name="a" maxlength="100">
<br>

<INPUT TYPE="submit" NAME="Submit" VALUE="Process Payments for frequency $frequency_clipped">
<br>
</li>
        <INPUT TYPE="hidden" NAME="Submit" type="HIDDEN" VALUE="Create Account">

</form>
</div>



};
#display it
print $html3;

#i'll miss you
exit;
