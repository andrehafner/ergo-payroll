# ergo-payroll
payroll system for automated payments on ergo<br>
Employers can pay in ERG, Token Count, or, in USD equivalent of a Token at the time of pay distribution


# requirements<br>
perl<br>
  -use CGI<br>
  -use DBI<br>
  -use Time::HiRes qw(gettimeofday)<br>
perlCGI<br>
apache<br>
mysql<br>
ergpy - https://github.com/mgpai22/ergpy<br>
<br>
# tokens supported in this script<br>
(more can be added of course, limit is whatever ergpy as well as my.ergoport.dev api supports)<br>
<br>
ERG<br>
comet = "0cd8c9f416e5b1ca9f986a7f10a84191dfb85941619e49e53c0dc30ebf83324b"<br>
migoreng = "0779ec04f2fae64e87418a1ad917639d4668f78484f45df962b0dec14a2591d2"<br>
neta = "472c3d4ecaa08fb7392ff041ee2e6af75f4a558810a74b28600549d5392810e8"<br>
paideia = "1fd6e032e8476c4aa54c18c1a308dce83940e8f4a28f576440513ed7326ad489"<br>
ergopad = "d71693c49a84fbbecd4908c94813b46514b18b67a99952dc1e6e4791556de413"<br>
egio = "00b1e236b60b95c2c6f8007a9d89bc460fc9e78f98b09faec9449007b40bccf3"<br>
exle = "007fd64d1ee54d78dd269c8930a38286caa28d3f29d27cadcb796418ab15c283"<br>

# explanation of each file<br>
ergo_wallet_gen.py: part of ergpy, this is used to create a wallet for each new company<br>
ergpy (folder): part of ergpy, required for function of the app<br>
sample_tosipayrolll.csv: template for download off of upload page<br>
tosipay.css: design element specifications for html generation<br>
tp_company_setup.html: static html landing page for company setup<br>
tp_cron_make_payment_scripts_12.pl: script to build payment script for 12 payment frequency for TOKENS<br>
tp_cron_make_payment_scripts_24.pl: script to build payment script for 24 payment frequency for TOKENS<br>
tp_cron_make_payment_scripts_52.pl: script to build payment script for 52 payment frequency for TOKENS<br>
tp_cron_make_payment_scripts_12erg.pl: script to build payment script for 12 payment frequency for ERG<br>
tp_cron_make_payment_scripts_24erg.pl: script to build payment script for 24 payment frequency for ERG<br>
tp_cron_make_payment_scripts_52erg.pl: script to build payment script for 52 payment frequency for ERG<br>
tp_cron_make_wallet.pl: script to check mymql database and create wallets for new companies automatically<br>
tp_cron_process_payments_tokens.pl: processes the python scripts made by numbered scripts above<br>
tp_cron_process_payments_tokens_erg.pl: processes the python scripts made by numbered scripts above<br>
tp_dashboard.pl: dashboard view for people to change individual entries<br>
tp_newuser.pl: process the data from tp_company_setup.html into mysql<br>
tp_payroll_view.pl: general view for all payments, also allows activating the company and pay frequencies<br>
tp_process.pl: process the data into mysql from tp_payroll_view.pl<br>
tp_upload.html: static html for upload page and to download the csv template<br>
tp_upload.pl: script for processing the uploaded csv from tp_upload.html<br>
uploads (folder): place where the company uploads go (prob delete these after ingestion)<br>

# functionality<br>
- Employers can pay in ERG, Token Count, or, in USD equivalent of a Token at the time of pay distribution<br>
- Employers create an account and are given a deposit wallet<br>
- Employers upload a csv of employees and preferences<br>
- Results are displayed<br>
- Employers can change individual employees in the dashboard<br>
- On the payroll view employers can see each pay frequency payout as well as activate and deactivate said payout<br>

# needing to be immplemented<br>
- Sendmail scripts (depends on your hosting server)<br>
- safety scripts that double check payment processing and maintenance<br>

# what needs to run on server in cron jobs<br>
- files with cron in the title ;)<br>
- UPCOMING - script modification to revert all paid employees back to not paid for the cycle right before the new payment is initiated, will remove when made<br>


