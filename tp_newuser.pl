#!/usr/bin/perl

use CGI;
use DBI;
use Number::Format 'format_number';
use List::Util qw/sum/;
use File::Copy;
use File::Path;
use Time::HiRes qw(gettimeofday);

#get vars from tp_company_setup.html
$query = new CGI;
$company_name = $query->param("company_name");
$company_wallet_id = $query->param("company_wallet_id");
$company_email_contact= $query->param("company_email_contact");
$password = $query->param("password");

#set vars
$html = ();

#this is for testing so I can see outputs in the browser
#$|=1;            # Flush immediately.
#print "Content-Type: text/plain\n\n";

#this gets the mysql password from a file so we don't have to store it in the script
open my $fh, '<', '/usr/lib/cgi-bin/sql.txt' or die "Can't open file $!";
$password = do { local $/; <$fh> };

#remove white spaces in the file for some reason beyond me why it's doing that
$password =~ s/^\s+//;
$password =~ s/\s+$//;

#let's get UNIX time
my $timecode = gettimeofday;

#definition of variables
my $db="tosipayroll";
my $host="localhost";
my $user="root";

#prep connect to MySQL database
my $dbh   = DBI->connect ("DBI:mysql:database=$db:host=$host",
  $user,
  $password)
  or die "Can't connect to database: $DBI::errstr\n";

#prep mysql statement to see if this person exists already
my $sql = "SELECT company_wallet_id FROM employer where company_wallet_id='$company_wallet_id';";

#prepare the query
my $sth = $dbh->prepare($sql);

#execute the query
$sth->execute();

## Retrieve the results of a row of data and put in an array
$" = "<br>";
while ( my @row = $sth->fetchrow_array( ) )  {
  push(@array, @row);
};

#check to see if the username exists
if ($array[0] eq $company_wallet_id){

$html = qq{Content-Type: text/html

<link rel="stylesheet" type="text/css" href="https://my.ergoport.dev/tosipayroll/tosipay.css">

<body>
<div>
<form class="form-style-7" enctype="multipart/form-data">
<form ACTION="/cgi-bin/tosipayroll/tp_newuser.pl" METHOD="post" enctype="multipart/form-data">
    <h1>Ergo Payroll -  Initial Company Setup</h1>
<div>
<br>
<br>
<body>
<br>
</body>
<body style="  background-image: linear-gradient(lightblue, white)">
<li>
<font size="+2">Error!</font size="+2">
<br>
<br>
USER ALREADY EXISTS, hit back and try again please!
<br>
</li>
        <INPUT TYPE="hidden" NAME="Submit" type="HIDDEN" VALUE="Create Account">

</form>
</div>



};

print $html;
exit;
}


#prep mysql statment to write data as a new user entry into mysql table
$sql = "insert into employer (company_name, company_wallet_id, company_email_contact, password, company_info_updated) VALUES ('$company_name', '$company_wallet_id', '$company_email_contact', MD5('$password'),'$timecode');";

#prepare the query
$sth = $dbh->prepare($sql);

#execute the query
$sth->execute();

#####hahahaha hahahaha hahahaha, i will fix this so we don't need to do it. it's to get the wallet seed but now that I know we can dump the python to a text and read it I'll fix it
sleep (2);

#prep mysql statement to see if this person exists already
$sql = "SELECT company_wallet_deposit_id FROM employer where company_wallet_id='$company_wallet_id';";

#prepare the query
$sth = $dbh->prepare($sql);

#execute the query
$sth->execute();

## Retrieve the results of a row of data and put in an array
$" = "<br>";
while ( my @row = $sth->fetchrow_array( ) )  {
  push(@array, @row);
};

#html to display and redirect the user to a results dash where they get their deposit address
$html = qq{Content-Type: text/html

<link rel="stylesheet" type="text/css" href="https://my.ergoport.dev/tosipayroll/tosipay.css">

<body>
<div>
<form class="form-style-7" enctype="multipart/form-data">
<form ACTION="/cgi-bin/tosipayroll/tp_newuser.pl" METHOD="post" enctype="multipart/form-data">
    <h1>TosiPayroll -  Initial Company Setup</h1>
<div>
<br>
<br>
<body>
<br>
</body>
<br>
<a href="https://my.ergoport.dev/tosipayroll/tp_upload.html">Upload Base Data</a>
<br><p>
<body style="  background-image: linear-gradient(lightblue, white)">
<li>
<font size="+2">Company Created!</font size="+2">
<br>
<br>
<b>Company Name:</b> $company_name <br>
<b>Company Email:</b> $company_email_contact <br>
<b>Company Wallet:</b> $company_wallet_id <br>
<b>Last Updated (in UNIX Time):</b> $timecode <br>
<br>
<b>Wallet address for deposits (this is unique to you):</b>@array[0]
<br>
<br>
</li>
        <INPUT TYPE="hidden" NAME="Submit" type="HIDDEN" VALUE="Create Account">

</form>
</div>



};

#print it!
print $html;

#goodbye
exit;

