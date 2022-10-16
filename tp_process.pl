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
my $freq = $query->param("a");
my $wallet = $query->param("wallet");
my $pass = $query->param("pass");
my $v12 = $query->param("v12");
my $v24 = $query->param("v24");
my $v52 = $query->param("v52");
my $v12d = $query->param("v12d");
my $v24d = $query->param("v24d");
my $v52d = $query->param("v52d");

my $token_amount = ();

#this is for testing so I can see outputs in the browser
#$|=1;            # Flush immediately.
#print "Content-Type: text/plain\n\n";


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
my $sql_access = "select * from employer where company_wallet_id='$wallet' and password=MD5('$pass');";

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
    <h1>Ergo Payroll - Process</h1>
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
#exit;

}



#set vars for frequency
my $sql_12 = ();
my $sql_24 = ();
my $sql_52 = ();
my $sql_12d = ();
my $sql_24d = ();
my $sql_52d = ();


#check which vars the ticked and set the mysql code for it
if ($v12 eq '12'){
$sql_12 = "company_12_frequency='yes'";
}

if ($v24 eq '24'){
$sql_24 = "company_24_frequency='yes'";
}  

if ($v52 eq '52'){
$sql_52 = "company_52_frequency='yes'";
}  

if ($v12d eq '12d'){
$sql_12d = "company_12_frequency='no'";
}

if ($v24d eq '24d'){
$sql_24d = "company_24_frequency='no'";
}

if ($v52d eq '52d'){
$sql_52d = "company_52_frequency='no'";
}

#put all options into an array
my @sql_list=($sql_12,$sql_24,$sql_52,$sql_12d,$sql_24d,$sql_52d);

#clean up the array
my @clean = grep /\S/, @sql_list;

#bring them back together with commans (no trailing comma)
my $sql_input = join(",",@clean);

#$sql_input =~ s/,+$//;

#write the eql query
$sql = "update employer set $sql_input where company_wallet_id='$wallet'";

#prepare the query
my $sth = $dbh->prepare($sql);

if ($sql_input ne ''){
#execute the query
$sth->execute();
}


#change var to readable text
if ($v12 eq '12'){
$v12 = "12";
}

if ($v24 eq '24'){
$v24 = "24";
}

if ($v52 eq '52'){
$v52 = "52";
}

if ($v12d eq '12d'){
$v12d = "12";
}

if ($v24d eq '24d'){
$v24d = "24";
}

if ($v52d eq '52d'){
$v52d = "52";
}





### first part of the html
my $html2 = qq{Content-Type: text/html

<link rel="stylesheet" type="text/css" href="https://my.ergoport.dev/tosipayroll/tosipay.css">

<body>
<div>
<form class="form-style-7" enctype="multipart/form-data">
<form ACTION="/cgi-bin/tosipayroll/tp_newuser.pl" METHOD="post" enctype="multipart/form-data">
    <h1>Ergo Payroll - Process</h1>
<div>
<br>
<br>
<body>
<br>
</body>
<body style="  background-image: linear-gradient(lightblue, white)">
<li>
<font size="+2">Active/Inactive</font size="+2"><br><br>
<b>Payment Frequency Status:<br><br>
Changed to Active:</b>$v12 $v24 $v52<br> 
<b>Changed to Inactive:</b>$v12d $v24d $v52d
};

print $html2;




$html3  = qq{
<br>
<br>
<b>Payments will process as follows:</b><br>
12 - Once a Month on the 1st of the Month<br>
24 - Twice a Month on the 1st and 15th of the Month<br>
52 - Every 7 Days (Fridays)<br>

</li>
        <INPUT TYPE="hidden" NAME="Submit" type="HIDDEN" VALUE="Create Account">

</form>
</div>



};

print $html3;

#night night bye bye
exit;








