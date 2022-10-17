#!/usr/bin/perl

use warnings;
use CGI;
use DBI;
use Number::Format 'format_number';
use List::Util qw/sum/;
use File::Copy;
use File::Path;

#initiate a new CGI and get value from submit button as well as other fields
my $query = new CGI;
my $submit = $query->param("Submit");
#remove some of the unneeded data from submit button
$submit =~ (s/Update Employee //);
my $wallet = $query->param("wallet");
my $pass = $query->param("pass");
my $wallet_edit = $query->param("$submit\+wallet_edit");
my $employee_email_contact = $query->param("$submit\+employee_email_contact");
my $employee_token_id = $query->param("$submit\+employee_token_id");
my $employee_token_count = $query->param("$submit\+employee_token_count");
my $employee_usd_amount = $query->param("$submit\+employee_usd_amount");
my $employee_pay_frequency = $query->param("$submit\+employee_pay_frequency");
my $employee_active_status = $query->param("$submit\+employee_active_status");
my $access  = $query->param("$submit\+access");
my $id = $query->param("$submit\+id");


#test version of login passthrough, will remove when real login system is in place
if ($wallet_edit eq ''){
  $wallet_edit = $wallet;
}

if ($wallet eq ''){
  $wallet = $wallet_edit;
}

#removing spaces from the inputs just in case
$employee_email_contact =~ s/^[^\+]*\+//;
$pass =~ s/^[^\+]*\+//;
$wallet_edit =~ s/^[^\+]*\+//;
$employee_token_id =~ s/^[^\+]*\+//;
$employee_token_count =~ s/^[^\+]*\+//;
$employee_usd_amount =~ s/^[^\+]*\+//;
$employee_pay_frequency =~ s/^[^\+]*\+//;
$employee_active_status =~ s/^[^\+]*\+//;
$access =~ s/^[^\+]*\+//;
$id =~ s/^[^\+]*\+//;

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


### this is a trick to allow editing without further password prompts, it refreshes to this page
if ($employee_active_status ne ''){


  my $sql_edit = "update employee set employee_email_contact='$employee_email_contact', employee_token_id='$employee_token_id', employee_token_count='$employee_token_count', employee_usd_amount='$employee_usd_amount', employee_pay_frequency='$employee_pay_frequency', employee_active_status='$employee_active_status' where id='$id';";

  #prepare the query
  my $sth_edit = $dbh->prepare($sql_edit);

  #execute the query
  $sth_edit->execute();

}

#declaring the first part of the page if they aren't authorized
my $html = ();


if ($wallet eq '' && $access eq ''){

  $html = ();

######HTML SECTION IGNORING INDENTING#######
  $html = qq{Content-Type: text/html

<link rel="stylesheet" type="text/css" href="https://my.ergoport.dev/tosipayroll/tosipay.css">

<body>
<div>
<form class="form-style-7" ACTION="/cgi-bin/tosipayroll/tp_dashboard.pl"  METHOD="post" enctype="multipart/form-data">
<form ACTION="/cgi-bin/tosipayroll/tp_dashboard.pl" METHOD="post" enctype="multipart/form-data">
    <h1>Ergo Payroll - Edit - Dashboard</h1>
<div>
<br>
<br>
<body>
<br>
<a href="https://my.ergoport.dev/tosipayroll/tp_upload.html">Upload More Base Data</a>
 | <a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_dashboard.pl">Individual Edit Dashboard</a>
 | <a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_payroll_view.pl?a=all.$wallet">Activate Payments</a>
<br><p>
</body>
<body style="  background-image: linear-gradient(lightblue, white)">
<li>
<font size="+2">Login to Dahsboard</font size="+2">
<br>
<br>
<label for="wallet"><b>Wallet:</b></label>
<input type="text" name="wallet" maxlength="200">
<br>
<label for="pass"><b>Password:</b></label>
<input type="password" name="pass" maxlength="50">
<br>
</li>
<br>

        <INPUT TYPE="submit" NAME="Submit" VALUE="Go to Dashboard">
<br>
<br>
</form>
</div>
};

#print it and exit leaving them at a login page to try again
print $html;
exit;

}

########END HTML##########

### password access check ######

my $sql_access = "select * from employer where company_wallet_id='$wallet' and password=MD5('$pass');";

if ($access ne ''){
  $sql_access = "select * from employer where company_wallet_id='$wallet' and password='$access';";
}

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
  elsif ($array_access[6] eq $access  && $array_access[6] ne ''){
  $access = $array_access[6];
  }
  #tell the user their pasword or id was wrong
  else {
### first part of the html IGNORING INDENTS
$html = qq{Content-Type: text/html

<link rel="stylesheet" type="text/css" href="https://my.ergoport.dev/tosipayroll/tosipay.css"> 
<body>
<div>
<form class="form-style-7" enctype="multipart/form-data">
<form ACTION="/cgi-bin/tosipayroll/tp_newuser.pl" METHOD="post" enctype="multipart/form-data">
    <h1>Ergo Payroll - Edit - Dashboard</h1>
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


#this is for testing so I can see outputs in the browser
#$|=1;            # Flush immediately.
#print "Content-Type: text/plain\n\n";

#time calculation
my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @weekDays = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
my $year = 1900 + $yearOffset;
my $theTime = "$months[$month] $dayOfMonth, $year - $weekDays[$dayOfWeek] $hour:$minute";


### first part of the html on the full page
$html = qq{Content-Type: text/html

<link rel="stylesheet" type="text/css" href="https://my.ergoport.dev/tosipayroll/tosipay.css">

<body>
<div>
<form class="form-style-7" ACTION="/cgi-bin/tosipayroll/tp_dashboard.pl" METHOD="post" enctype="multipart/form-data">
<form ACTION="/cgi-bin/tosipayroll/tp_dashboard.pl" METHOD="post" enctype="multipart/form-data">
    <h1>Ergo Payroll - Edit - Dashboard</h1>
<div>
<br>
<br>
<body>
<br>
<a href="https://my.ergoport.dev/tosipayroll/tp_upload.html">Upload More Base Data</a>
 | <a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_dashboard.pl">Individual Edit Dashboard</a>
 | <a href="https://my.ergoport.dev/cgi-bin/tosipayroll/tp_payroll_view.pl?a=all.$wallet">Activate Payments</a>
<br><p>
</body>
<body style="  background-image: linear-gradient(lightblue, white)">
<br>

};

print $html;

######END HTML#######

######## mysql initial base data and other vars #########

#declaring values for later use
my $sql = ();
my $sth = ();

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

#getting all info from the employee that matches the company wallet
$sql = "select * from employee where company_wallet_id='$wallet';";

#prepare the query
my $sth = $dbh->prepare($sql);

#execute the query
$sth->execute();

#put it into an array and loop it with a while
$" = "<br>";
while (my @row = $sth->fetchrow_array( ) )  {
  push(@array, @row);


#######HTML IGNORING INDENTS#######
#second part of html page
$html2  = qq{
<li>
<br>
<b>Employee Number:</b> $array[0] <br>
<b>Wallet:</b> $array[3] <br>

<br>
<label for="employee_email_contact"><b>Email:</b></label>
<input type="text" value="$array[4]" name="$array[0]+employee_email_contact" maxlength="50">
<br>
<label for="employee_token_id"><b>Paid in:</b></label>
<input type="text" value="$array[5]" name="$array[0]+employee_token_id" maxlength="100">
<br>
<label for="employee_token_count"><b>Number of Pure Tokens</b> (leave blank if paying in USD equivalent):</label>
<input type="text" value="$array[6]" name="$array[0]+employee_token_count" maxlength="100">
<br>
<label for="employee_usd_amount"><b>Paid in USD Amount</b> (leave blank if paying in pure token count):</label>
<input type="text" value="$array[7]" name="$array[0]+employee_usd_amount" maxlength="100">
<br>
<label for="employee_pay_frequency">Pay Frequencey per year (12, 24, 52)<b>:</b></label>
<input type="text" value="$array[8]" name="$array[0]+employee_pay_frequency" maxlength="100">
<br>
<label for="employee_active_status"><b>Active?:</b></label>
<input type="text" value="$array[10]" name="$array[0]+employee_active_status" maxlength="100">
<br>

<b>Payment History:</b> $array[9] <br>
<b>Employee Info Last Updated:</b> $array[11] <br>
<b>Paid this segment?</b> (yes or no): $array[12] <br><br>

<input type="hidden" value="@array[0]" name="$array[0]+id" maxlength="100">
<input type="hidden" value="$access" name="$array[0]+access"  maxlength="200">
<input type="hidden" value="$wallet" name="$array[0]+wallet_edit"  maxlength="200">
<input type="hidden" value="$wallet" name="$array[0]+wallet"  maxlength="200">

<INPUT TYPE="submit" NAME="Submit" VALUE="Update Employee $array[0]">
</li>

};

#print that html
print $html2;
  @array = ();
  
};


#closing part of page
$html3  = qq{
<br>
        <INPUT TYPE="hidden" NAME="Submit" type="HIDDEN" VALUE="Create Account">

</form>
</div>



};

#print it
print $html3;

#don't go so soon!
exit;
