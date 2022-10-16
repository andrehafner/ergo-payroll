#!/usr/bin/perl

use CGI;
use DBI;
use Number::Format 'format_number';
use List::Util qw/sum/;
use File::Copy;
use File::Path;
use Time::HiRes qw(gettimeofday);

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

#declaring some vars
my $pyfile = 'python3 ergo_wallet_gen.py';
my @wallet = ();
my $sql = ();
my $sth = ();
my $sql2 = ();
my $sth2 = ();


#makeing a 1 second loop to catch all new accounts and give them a new wallet
while (1) {

#prep mysql statement to see if employer has a seed phrase yet
$sql = "SELECT id FROM employer where company_seed_name IS NULL or '' and company_wallet_deposit_id IS NULL or '';";

#prepare the query
$sth = $dbh->prepare($sql);

#execute the query
$sth->execute();

## Retrieve the results of a row of data and put in an array
$" = "<br>";
while ( my @row = $sth->fetchrow_array( ) )  {
  push(@array, @row);
};


#if no seed, run the wallet maker with a system call and capture the result
if ($array[0] ne ''){
@wallet = qx($pyfile);
print @wallet;


#prep mysql statment to write data int seed column
$sql2 = "update employer set company_seed_name='@wallet[0]', company_wallet_deposit_id='@wallet[1]' where id='@array[0]';";

#prepare the query
$sth2 = $dbh->prepare($sql2);

#execute the query
$sth2->execute();

#$rc = $dbh->disconnect  || warn $dbh->errstr;

#wipe array
@array = ();

}

#loop
sleep 1;
}

#goodbye
exit;

