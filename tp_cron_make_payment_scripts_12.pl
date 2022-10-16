#!/usr/bin/perl

#use warnings;
use CGI;
use DBI;
use Number::Format 'format_number';
use List::Util qw/sum/;
use File::Copy;
use File::Path;

#setting a var for future use
my $token_amount = ();

#this is for testing so I can see outputs in the browser
#$|=1;            # Flush immediately.


##################

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



#set a filename var so we can later search for the 12 paycycle to run
my $end_filename = "_12_tokens.py";

#this mysql call gets the company info as a base 
my $sql_access_main = "select company_wallet_deposit_id, company_wallet_id, company_seed_name from employer where company_wallet_deposit_id!='' and company_wallet_id!='' and company_active='yes' and company_12_frequency='yes';";

#prepare the query
my $sth_access_main = $dbh->prepare($sql_access_main);

#execute the query
$sth_access_main->execute();



#put it into an array
$" = "<br>";
while (my @row_access_main = $sth_access_main->fetchrow_array( ) )  {
	push(@array_access_main, @row_access_main);

#sometimes these things get spaces and we need to remove them just in case
$A = chomp($array_access_main[2]);

# Open a file named "output.txt"; die if there's an error
open my $fh, '>', "/usr/lib/payments_payroll/$array_access_main[1]$end_filename";

#here we start literally writing the python file that is the payment script
my $p1 = 'import sys

from contextlib import redirect_stdout
from ergpy import appkit
from ergpy import helper_functions

node_url: str = "http://213.239.193.208:9053/"
ergo = appkit.ErgoAppKit(node_url)

wallet_mnemonic = "';

print $fh $p1;

#this gets the mnemonic
print $fh "$array_access_main[2]";

my $p2 = '"

c_wallet_address = "';

print $fh $p2;

#this gets the company wallet address (which is only needed for internal tracking)
print $fh "$array_access_main[1]";

my $p3 = '"

wallet_address = helper_functions.get_wallet_address(ergo=ergo, amount=1, wallet_mnemonic=wallet_mnemonic)[0]

print(wallet_address)

comet = "0cd8c9f416e5b1ca9f986a7f10a84191dfb85941619e49e53c0dc30ebf83324b"
migoreng = "0779ec04f2fae64e87418a1ad917639d4668f78484f45df962b0dec14a2591d2"
neta = "472c3d4ecaa08fb7392ff041ee2e6af75f4a558810a74b28600549d5392810e8"
paideia = "1fd6e032e8476c4aa54c18c1a308dce83940e8f4a28f576440513ed7326ad489"
ergopad = "d71693c49a84fbbecd4908c94813b46514b18b67a99952dc1e6e4791556de413"
egio = "00b1e236b60b95c2c6f8007a9d89bc460fc9e78f98b09faec9449007b40bccf3"
exle = "007fd64d1ee54d78dd269c8930a38286caa28d3f29d27cadcb796418ab15c283"
flux = "e8b20745ee9d18817305f32eb21015831a48f02d40980de6e849f886dca7f807"



receiver_addresses = [
    ';

print $fh $p3;

#this mySQL will get the employee information
$sql = "select e_company_wallet_id, employee_token_id from employee where company_wallet_id='@array_access_main[1]' and employee_token_id!='erg' and employee_pay_frequency='12' and employee_active_status='yes' order by id;";

#prepare the query
my $sth = $dbh->prepare($sql);

#execute the query
$sth->execute();

#put sql query into an array
$" = "<br>";
while (my @row = $sth->fetchrow_array( ) )  {
	push(@array, @row);
}

#set an int for a loop through
my $int = '0';

#start the loop
foreach (@array){

#print more of the file (yes, indentations are important to leave as is and ugly here for python)
if (@array[$int+2] ne '' && @array[$int] ne ''){
print $fh "\"@array[$int]\"";
print $fh ",
    ";
$int = $int + 2;
}

if (@array[$int+2] eq '' && @array[$int] ne ''){
print $fh "\"@array[$int]\"";
print $fh "
";
$int = $int + 2;
}
}


print $fh "]

tokens = [
    ";


#clear the array
@array = ();

#another pass at the data for the token data
$sql = "select employee_token_id, employee_token_id from employee where company_wallet_id='@array_access_main[1]' and employee_token_id!='erg' and employee_pay_frequency='12' and employee_active_status='yes' order by id;";

#prepare the query
my $sth = $dbh->prepare($sql);

#execute the query
$sth->execute();

#put it into an array
$" = "<br>";
while (my @row = $sth->fetchrow_array( ) )  {
  push(@array, @row);
}

my $int = '0';

foreach (@array){


if (@array[$int+2] ne '' && @array[$int] ne '' && @array[$int+1] ne 'erg'){



####token ID define
$token_name = "UNKNOWN";

if (@array[$int+1] eq "0cd8c9f416e5b1ca9f986a7f10a84191dfb85941619e49e53c0dc30ebf83324b"){
$token_name = "comet";
}

elsif (@array[$int+1] eq "0779ec04f2fae64e87418a1ad917639d4668f78484f45df962b0dec14a2591d2"){
$token_name = "migoreng";
}

elsif (@array[$int+1] eq "472c3d4ecaa08fb7392ff041ee2e6af75f4a558810a74b28600549d5392810e8"){
$token_name = "neta";
}

elsif (@array[$int+1] eq "1fd6e032e8476c4aa54c18c1a308dce83940e8f4a28f576440513ed7326ad489"){
$token_name = "paideia";
}

elsif (@array[$int+1] eq "d71693c49a84fbbecd4908c94813b46514b18b67a99952dc1e6e4791556de413"){
$token_name = "ergopad";
}

elsif (@array[$int+1] eq "00b1e236b60b95c2c6f8007a9d89bc460fc9e78f98b09faec9449007b40bccf3"){
$token_name = "egio";
}

elsif (@array[$int+1] eq "007fd64d1ee54d78dd269c8930a38286caa28d3f29d27cadcb796418ab15c283"){
$token_name = "exle";
}

elsif (@array[$int+1] eq "e8b20745ee9d18817305f32eb21015831a48f02d40980de6e849f886dca7f807"){
$token_name = "flux";
}

#more file printing
print $fh "\[$token_name\]";
print $fh ",
    ";
$int = $int + 2;
}

if (@array[$int+2] eq '' && @array[$int] ne '' && @array[$int+1] ne 'erg'){


####token ID define
$token_name = "UNKNOWN";

if (@array[$int+1] eq "0cd8c9f416e5b1ca9f986a7f10a84191dfb85941619e49e53c0dc30ebf83324b"){
$token_name = "comet";
}

elsif (@array[$int+1] eq "0779ec04f2fae64e87418a1ad917639d4668f78484f45df962b0dec14a2591d2"){
$token_name = "migoreng";
}

elsif (@array[$int+1] eq "472c3d4ecaa08fb7392ff041ee2e6af75f4a558810a74b28600549d5392810e8"){
$token_name = "neta";
}

elsif (@array[$int+1] eq "1fd6e032e8476c4aa54c18c1a308dce83940e8f4a28f576440513ed7326ad489"){
$token_name = "paideia";
}

elsif (@array[$int+1] eq "d71693c49a84fbbecd4908c94813b46514b18b67a99952dc1e6e4791556de413"){
$token_name = "ergopad";
}

elsif (@array[$int+1] eq "00b1e236b60b95c2c6f8007a9d89bc460fc9e78f98b09faec9449007b40bccf3"){
$token_name = "egio";
}

elsif (@array[$int+1] eq "007fd64d1ee54d78dd269c8930a38286caa28d3f29d27cadcb796418ab15c283"){
$token_name = "exle";
}

elsif (@array[$int+1] eq "e8b20745ee9d18817305f32eb21015831a48f02d40980de6e849f886dca7f807"){
$token_name = "flux";
}

print $fh "\[$token_name\]";
print $fh "
";
$int = $int + 2;
}
}


print $fh "]

amount_tokens = [
    ";


@array = ();

$sql = "select employee_token_count, employee_token_id, employee_usd_amount from employee where company_wallet_id='@array_access_main[1]' and employee_token_id!='erg' and employee_pay_frequency='12' and employee_active_status='yes' order by id;";

#prepare the query
my $sth = $dbh->prepare($sql);

#execute the query
$sth->execute();

#put it into an array
$" = "<br>";
while (my @row = $sth->fetchrow_array( ) )  {
  push(@array, @row);
}



my $int = '0';

foreach (@array){


####token ID define

if (@array[$int+1] eq "0cd8c9f416e5b1ca9f986a7f10a84191dfb85941619e49e53c0dc30ebf83324b"){
$token_name = "comet";
}

elsif (@array[$int+1] eq "0779ec04f2fae64e87418a1ad917639d4668f78484f45df962b0dec14a2591d2"){
$token_name = "migoreng";
}

elsif (@array[$int+1] eq "472c3d4ecaa08fb7392ff041ee2e6af75f4a558810a74b28600549d5392810e8"){
$token_name = "neta";
}

elsif (@array[$int+1] eq "1fd6e032e8476c4aa54c18c1a308dce83940e8f4a28f576440513ed7326ad489"){
$token_name = "paideia";
}

elsif (@array[$int+1] eq "d71693c49a84fbbecd4908c94813b46514b18b67a99952dc1e6e4791556de413"){
$token_name = "ergopad";
}

elsif (@array[$int+1] eq "00b1e236b60b95c2c6f8007a9d89bc460fc9e78f98b09faec9449007b40bccf3"){
$token_name = "egio";
}

elsif (@array[$int+1] eq "007fd64d1ee54d78dd269c8930a38286caa28d3f29d27cadcb796418ab15c283"){
$token_name = "exle";
}

elsif (@array[$int+1] eq "e8b20745ee9d18817305f32eb21015831a48f02d40980de6e849f886dca7f807"){
$token_name = "flux";
}



### price check for conversion in USD to token count

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

if (@array[$int+2] ne ''){
$token_amount = @array[$int+2] / @array_price[0];
}


if (@array[$int+3] ne '' && @array[$int] ne '' && @array[$int+5] ne '' && @array[$int+1] ne 'erg'){
print $fh "\[@array[$int]\]";
print $fh ",
    ";
}
if (@array[$int+3] ne '' && @array[$int] ne '' && @array[$int+5] eq '' && @array[$int+1] ne 'erg'){
print $fh "\[@array[$int]\]";
print $fh ",
    ";
}


if (@array[$int+3] eq '' && @array[$int] ne '' && @array[$int+5] ne '' && @array[$int+1] ne 'erg'){
print $fh "\[@array[$int]\]";
print $fh ",
    ";
}


if (@array[$int+3] ne '' && @array[$int+2] ne '' && @array[$int+5] ne '' && @array[$int+1] ne 'erg'){
print $fh "\[$token_amount\]";
print $fh ",
    ";
}

if (@array[$int+3] ne '' && @array[$int+2] ne '' && @array[$int+5] eq '' && @array[$int+1] ne 'erg'){
print $fh "\[$token_amount\]";
print $fh ",
    ";
}


if (@array[$int+3] eq '' && @array[$int+2] ne '' && @array[$int+5] ne '' && @array[$int+1] ne 'erg'){
print $fh "\[$token_amount\]";
print $fh ",
    ";
}


if (@array[$int+3] eq '' && @array[$int] ne ''  && @array[$int+5] eq '' && @array[$int+1] ne 'erg'){
print $fh "\[@array[$int]\]";
print $fh "
";
}

if (@array[$int+3] eq '' && @array[$int+2] ne ''  && @array[$int+5] eq '' && @array[$int+1] ne 'erg'){
print $fh "\[$token_amount\]";
print $fh "
";
}

$int = $int + 3;


@array_price = ();


}



print $fh "]

amount = [";


@array = ();


$sql = "select employee_token_count, employee_token_id, employee_usd_amount from employee where company_wallet_id='@array_access_main[1]' and employee_token_id!='erg' and employee_pay_frequency='12' and employee_active_status='yes' order by id;";

#prepare the query
my $sth = $dbh->prepare($sql);

#execute the query
$sth->execute();

#put it into an array
$" = "<br>";
while (my @row = $sth->fetchrow_array( ) )  {
  push(@array, @row);
}

my $int = '0';

#set erg amount to min, ergo only send has to be done in another script
foreach (@array){


if (@array[$int+3] ne '' && @array[$int] ne '' && @array[$int+5] ne '' && @array[$int+1] ne 'erg'){
print $fh "0.0001";
print $fh ",";
}

if (@array[$int+3] ne '' && @array[$int] ne '' && @array[$int+5] eq '' && @array[$int+1] ne 'erg'){
print $fh "0.0001";
print $fh ",";
}


if (@array[$int+3] eq '' && @array[$int] ne '' && @array[$int+5] ne '' && @array[$int+1] ne 'erg'){
print $fh "0.0001";
print $fh ",";
}


if (@array[$int+3] ne '' && @array[$int+2] ne '' && @array[$int+5] ne '' && @array[$int+1] ne 'erg'){
print $fh "0.0001";
print $fh ",";
}

if (@array[$int+3] ne '' && @array[$int+2] ne '' && @array[$int+5] eq '' && @array[$int+1] ne 'erg'){
print $fh "0.0001";
print $fh ",";
}


if (@array[$int+3] eq '' && @array[$int+2] ne '' && @array[$int+5] ne '' && @array[$int+1] ne 'erg'){
print $fh "0.0001";
print $fh ",";
}


if (@array[$int+3] eq '' && @array[$int] ne ''  && @array[$int+5] eq '' && @array[$int+1] ne 'erg'){
print $fh "0.0001";
print $fh "";
}

if (@array[$int+3] eq '' && @array[$int+2] ne ''  && @array[$int+5] eq '' && @array[$int+1] ne 'erg'){
print $fh "0.0001";
print $fh "";
} 

$int = $int + 3;

}
        print $fh "\]";

#here is the rest of the file
my $endoffile = '


output_main = helper_functions.send_token(ergo=ergo, amount=amount, amount_tokens=amount_tokens,
                                  receiver_addresses=receiver_addresses, tokens=tokens,
                                  wallet_mnemonic=wallet_mnemonic)

with open(c_wallet_address, \'w\') as f:
    with redirect_stdout(f):
        print(output_main)


helper_functions.exit()';


print $fh $endoffile;

#clear this array and start the loop again if there are more companies that need to pay out
@array_access_main = ();


};

#buh bye
exit;
