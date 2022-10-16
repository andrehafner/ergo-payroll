#!/usr/bin/perl

#use warnings;
use CGI;
use DBI;
use Number::Format 'format_number';
use List::Util qw/sum/;
use File::Copy;
use File::Path;
use Time::HiRes qw(gettimeofday);
use IPC::Run 'run';
use Capture::Tiny ':all';
#use warnings;

my $token_amount = ();

#this is for testing so I can see outputs in the browser
#$|=1;            # Flush immediately.
#print "Content-Type: text/plain\n\n";

#declare some vars
my $pay_frequency = '';

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


### look in DIR for scripts to run, ingest the filenames into an array
my @files = </usr/lib/payments_payroll/*_tokens.py>;

#declare the int for a loop
my $int = "0";

#fire up the loop
foreach (@files){

#set a var so we can delete the file when finished
my $del_file = @files[$int];

#set command, dir, filename for system call
my $pyfile = "python3 @files[$int]";

#system call to run python script
my @pay = qx($pyfile);

unlink($del_file);

#remove the dir from string
@files[$int] =~ s/\/usr\/lib\/payments_payroll\///s;

#look at filename for the pay cycle
if (@files[$int] =~ m/_12_/){
$pay_frequency = '12';
}
#look at filename for the pay cycle
elsif (@files[$int] =~ m/_24_/){
$pay_frequency = '24';
}
#look at filename for the pay cycle
elsif (@files[$int] =~ m/_52_/){
$pay_frequency = '52';
}

#feedback when run in the console
print "(@files[$int] \n\n";


#wipe everything after the _ in the filename, this gets us the pure wallet number of file
@files[$int] =~ s/_.*//s;

#remove trailing and pre spaces
@files[$int] =~ s/^\s+//;
@files[$int] =~ s/\s+$//;

#lol, i should rename this, getting the var ito another var
my $tessst = @files[$int];

#don't need to do this again, can remove
$tessst =~ s/^\s+//;
$tessst =~ s/\s+$//;

#prob can just declare this var above and remove the end from it instead of this far down
#this is where the TX will now be since the python script wrote it here
# DON'T ask me why the python script won't do a proper STDOUT like the create wallet python did, this is the only way i an get the tx for now
$tessst = "/usr/lib/cgi-bin/tosipayroll/$tessst";

#this gets the tx from the file
open $fh, '<', "$tessst" or die "Can't open file $!";
$tx_address = do { local $/; <$fh> };

#clean up before and after spaces just in case
$tx_address =~ s/^\s+//;
$tx_address =~ s/\s+$//;

#get server time
my $timecode = gettimeofday;

#execute only if file exists
if (@files[$int] ne ''){
#prep mysql statement to see if this person exists already
my $sql = "update employee set paid_this_sgement='yes', 
employee_pay_history='$tx_address' 
where company_wallet_id='@files[$int]' 
and employee_pay_frequency='$pay_frequency' 
and employee_active_status='yes' and employee_token_id!='erg';";

#more outputs for testing when running from terminal
print "\n\n $tx_address  \n\n";
print "\n\n @files[$int]  \n\n";
print "\n\n $pay_frequency  \n\n";


#prepare the query
my $sth = $dbh->prepare($sql);

#execute the query
$sth->execute();
}

#step up the int for the loop
$int = $int + 1;

#delete the file
unlink($tessst)
}

#bye!!!
exit;
