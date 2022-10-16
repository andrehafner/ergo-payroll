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
my $file = $query->param("file");
my $company_wallet_id = $query->param("company_wallet_id");
my $pass = $query->param("password");

my $access = ();

#lets remove all strange character from the filename
$file =~ s/[\p{Pi}\p{Pf}\p{Ps}\p{Pd}\p{Pe}\p{Pc}\p{Sc}\p{Sm}\p{Z}'"]//g;

#this is for testing so I can see outputs in the browser
#$|=1;            # Flush immediately.
#print "Content-Type: text/plain\n\n";

#time calculation
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
my $year = 1900 + $yearOffset;
my $theTime = "$months[$month] $dayOfMonth, $year - $weekDays[$dayOfWeek] $hour:$minute";

#make sure it's a CSV
#if ($file !~ /\.csv$/i) {
#print "\n\n\n\t$file is not a CSV type file. Please hit your back button and upload a CSV.\n";
#exit;
#}

##declcare a few vars
my $html2 = '';
my $html25 = '';
my $html26 = '';
my $html3 = '';
#list of supported tokens
my $token_lists = "0cd8c9f416e5b1ca9f986a7f10a84191dfb85941619e49e53c0dc30ebf83324b 0779ec04f2fae64e87418a1ad917639d4668f78484f45df962b0dec14a2591d2 472c3d4ecaa08fb7392ff041ee2e6af75f4a558810a74b28600549d5392810e8 1fd6e032e8476c4aa54c18c1a308dce83940e8f4a28f576440513ed7326ad489 d71693c49a84fbbecd4908c94813b46514b18b67a99952dc1e6e4791556de413 00b1e236b60b95c2c6f8007a9d89bc460fc9e78f98b09faec9449007b40bccf3 007fd64d1ee54d78dd269c8930a38286caa28d3f29d27cadcb796418ab15c283 e8b20745ee9d18817305f32eb21015831a48f02d40980de6e849f886dca7f807 erg";



### first part of the html
my $html = qq{Content-Type: text/html

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
<a href="https://my.ergoport.dev/tosipayroll/tp_upload.html">Upload More Base Data</a>
 | <a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_dashboard.pl">Individual Edit Dashboard</a>
 | <a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_payroll_view.pl?a=all.$company_wallet_id">Activate Payments</a>
<br><p>
</body>
<body style="  background-image: linear-gradient(lightblue, white)">
<li>
<font size="+2">CSV Import Results</font size="+2">
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

my $sql_access = "select * from employer where company_wallet_id='$company_wallet_id' and password=MD5('$pass');";

#prepare the query
my $sth_access = $dbh->prepare($sql_access);

#execute the query
$sth_access->execute();

#put it into an array
$" = "<br>";
while (my @row_access = $sth_access->fetchrow_array( ) )  {
  push(@array_access, @row_access);

};

#set user to correct id in the mysql table if they exist
if ($array_access[2] eq $company_wallet_id && $array_access[6] ne ''){
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




#filename and upload
my $upload_filehandle = $query->upload("file");

#path to store uploads
my $uploadDir = "/usr/lib/cgi-bin/tosipayroll/uploads";
	       # /usr/lib/cgi-bin/tosipayroll/uploads
#lets name it
my $csvName = "$hour-$minute-$second-$file";

#lets uplaod it
open ( UPLOADFILE, ">$uploadDir/$csvName" )
 or die "$!"; 
binmode UPLOADFILE; 

while ( <$upload_filehandle> ) 
{ print UPLOADFILE; } 
close UPLOADFILE;

#open the file for reading
my $file = "$uploadDir/$csvName";
open(FH, $file) or die("File $file not found");

#put the contents of the csv into an array
my @list;
open (my $csv, '<', $file) || die "cant open";
foreach (<$csv>) {
   chomp;
   my @fields = split(/\,/);
   push @list, $fields[0], $fields[1], $fields[2], $fields[3], $fields[4], $fields[5], $fields[6], $fields[7], $fields[8];
}

    close(FH);

#get some int's ready for a looooooop
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

#start the while loop
while (@list[$n] ne ''){


$sql_lu = "select id from employee where company_wallet_id='$array_access[2]' and e_company_wallet_id='$list[$n2]';";
#$sql_lu = "select id from employee where company_wallet_id='55555wallet5555555' and e_company_wallet_id='9eat9sd99090asd09qw0asd90909e0w9eqkdifbvbhf';";

#prepare the query
$sth_lu = $dbh->prepare($sql_lu);

#execute the query
$sth_lu->execute();


## Retrieve the results of a row of data and put in an array
$" = "<br>";
while (my @row_lu = $sth_lu->fetchrow_array( ) )  {
  push(@array_lu, @row_lu);

};


$loc = index($token_lists,$list[$n4]);
#print "$loc\n";

#get wallet lengths to check for mistakes
$string_len_c_wallet =  length($list[$n1]);
$string_len_e_wallet =  length($list[$n2]);

#kick back error if bad email
if ($list[$n3] eq ''){
$list[$n3] = "No eMail";
$email_to_wallet = "-> using wallet $list[$n2]";
}

#kick back error it wallet less than 51
if ($string_len_c_wallet < '51'){
$html2 = "ERROR Employee $list[$n3] not ingested: Company Wallet less than 51 characters! -> $list[$n1] \n <br>";
#print "ERROR Employee $list[$n3] not ingested: Company Wallet less than 51 characters! -> $list[$n1] \n";
}

#kick back error it wallet less than 51
elsif ($string_len_e_wallet < '51'){
$html2 = "ERROR Employee $list[$n3] not ingested: Employee Wallet less than 51 characters! -> $list[$n2]\n <br>";
#print "ERROR Employee $list[$n3] not ingested: Company Wallet less than 51 characters! -> $list[$n2] \n";
}

#kick back error if trying to pay in both
elsif ($list[$n5] ne '' && $list[$n6] ne ''){
$html2 = "ERROR Employee $list[$n3] not ingested: You can not pay in BOTH tokens and ERG at the same time\n <br>";
#print "ERROR Employee $list[$n3] not ingested: Company Wallet less than 51 characters! -> $list[$n2] \n";
}

#kick back error if unsupported token
elsif ($loc eq '-1'){
$html2 = "ERROR Employee $list[$n3] not ingested: $list[$n4] $loc Token ID is not supported or incorreclty typed \n <br>";
#print "ERROR Employee $list[$n3] not ingested: $list[$n7] Pay Frequency not 24, 26, or 52 \n";
}

#kick back error if unsupported frequency
elsif ($list[$n7] ne '52' && $list[$n7] ne '24' && $list[$n7] ne '12'){
$html2 = "ERROR Employee $list[$n3] not ingested: $list[$n7] Pay Frequency not 24, 26, or 52 \n <br>";
#print "ERROR Employee $list[$n3] not ingested: $list[$n7] Pay Frequency not 24, 26, or 52 \n";
}

#check for back email and kick back error
elsif (($list[$n3] !~ m/\./ || $list[$n3] !~ m/@/) && $list[$n3] ne ''  && $list[$n3] !~ m/No eMail/){
$html2 = "ERROR Employee $list[$n3] not ingested: Check email address format -> $list[$n3] \n <br>";
#print "ERROR Employee $list[$n3] not ingested: Check email address format -> $list[$n3] \n";
}

######## mysql to insert the data into the table ##########
#update if already there
elsif (@array_lu[0] > '0' and @array_lu[0] ne ''){
$html2 = "UPDATED Employee: $list[$n3] \n <br>";
#print "UPDATED Employee: $list[$n3] \n";
#prep the sql statement
$sql = "update employee set company_name='$list[$n]', company_wallet_id='$array_access[2]', e_company_wallet_id='$list[$n2]', employee_email_contact='$list[$n3]', employee_token_id='$list[$n4]', employee_token_count='$list[$n5]', employee_usd_amount='$list[$n6]', employee_pay_frequency='$list[$n7]', employee_active_status='$list[$n8]' where id='$array_lu[0]';";
}

#insert new if not there
elsif (@array_lu[0] < '1' or @array_lu[0] eq ''){
$sql = "insert into employee (company_name,company_wallet_id,e_company_wallet_id,employee_email_contact,employee_token_id,employee_token_count,employee_usd_amount,employee_pay_frequency,employee_active_status,employee_pay_history) VALUES ('$list[$n]','$array_access[2]','$list[$n2]','$list[$n3]','$list[$n4]','$list[$n5]','$list[$n6]','$list[$n7]','$list[$n8]', '#start# ');";
$html2 = "ADDED NEW Employee: $list[$n3] $email_to_wallet \n <br>";
#print "ADDED NEW Employee: $list[$n3] $email_to_wallet \n";
}
  
print $html2;


#prepare the query
$sth = $dbh->prepare($sql);

#execute the query
$sth->execute();

#step the ints for another loop
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



#print token import info
my $html254 = "<br><br>****************<br><b><font size=\"+1\">Employees Paid In Pure Token Count</font size=\"+1\"></b><br><br>";
print $html254;


###### get the counts of the import for data display
my $sql_counts = "select employee_token_id, SUM(employee_token_count), COUNT(company_wallet_id), COUNT(employee_pay_frequency), employee_pay_frequency from employee where employee_token_count IS NOT NULL and employee_usd_amount='' and company_wallet_id='$array_access[2]' group by employee_token_id, employee_pay_frequency order by employee_pay_frequency;";

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


### yup, lets price check this

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


## once a month
if (@array_counts[4] eq '12'){
$total_i_token_price_12 = $array_counts[1] * $array_price[0];
$total_USD_token_price_12 = $total_USD_token_price_12 + $total_i_token_price_12;
$total_i_token_price_12 = sprintf("%.2f", $total_i_token_price_12);

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts[4]<br>
<b>Sum Per Month: </b>@array_counts[1] <br>
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
$total_i_token_price_24 = $total_i_token_price_24 * 2;
$total_i_token_price_24 = sprintf("%.2f", $total_i_token_price_24);
@array_counts[1] = @array_counts[1] * 2;

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts[4]<br>
<b>Sum Per Month: </b>@array_counts[1] <br>
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
$total_i_token_price_52 = $total_i_token_price_52 * 4;
$total_i_token_price_52 = sprintf("%.2f", $total_i_token_price_52);
@array_counts[1] = @array_counts[1] * 4;

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts[4]<br>
<b>Sum Per Month: </b>@array_counts[1] <br>
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


### yup, lets price check this

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
<b>Sum of Tokens Per Month: </b>$total_i_token_price_12<br>
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
$total_i_token_price_24 = ($array_counts_usd[1] / $array_price[0]) * 2;
$total_USD_token_price_24 = ($total_USD_token_price_24 + @array_counts_usd[1]);
$total_i_token_price_24 = sprintf("%.2f", $total_i_token_price_24);
@array_counts_usd[1] = @array_counts_usd[1] * 2;

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts_usd[4]<br>
<b>Sum of Tokens Per Month: </b>$total_i_token_price_24<br>
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
$total_i_token_price_52 = ($array_counts_usd[1] / $array_price[0]) * 4;
$total_USD_token_price_52 = ($total_USD_token_price_52 + @array_counts_usd[1]);
$total_i_token_price_52 = sprintf("%.2f", $total_i_token_price_52);
@array_counts_usd[1] = @array_counts_usd[1] * 4;

$html25 = "<br><b>Token:</b> $token_name <br>
<b>Payments Per Year: </b> $array_counts_usd[4]<br>
<b>Sum of Tokens Per Month: </b>$total_i_token_price_52<br>
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


$total_USD_token_price_24 = $total_USD_token_price_24 * 2;
$total_USD_token_price_52 = $total_USD_token_price_52 * 4;

$total_USD_token_price_total = $total_USD_token_price_12 + $total_USD_token_price_24 + $total_USD_token_price_52;


###get the number of employees that were updated/added
my $sql_ecounts = "select count(company_wallet_id) from employee where company_wallet_id='$array_access[2]';";

#prepare the query
my $sth_ecounts = $dbh->prepare($sql_ecounts);

#execute the query
$sth_ecounts->execute();

$total_USD_token_price_total = sprintf("%.2f", $total_USD_token_price_total);

## Retrieve the results of a row of data and put in an array
$" = "<br>";
while (my @row_ecounts = $sth_ecounts->fetchrow_array( ) )  {
  push(@array_ecounts, @row_ecounts);

$html26 = "<br><br><b>Total Employees:</b> @array_ecounts[0]<br>
<br>
<br>
****************<br><b><font size=\"+1\">
<b>Total Cost in USD for known coins/tokens per month: \$$total_USD_token_price_total
</b></font size=\"+1\">

";

print $html26;

@array_counts = ();
};


$html3  = qq{
<br>
</li>
        <INPUT TYPE="hidden" NAME="Submit" type="HIDDEN" VALUE="Create Account">

</form>
</div>

};

print $html3;

exit;
