#!/usr/local/bin/perl
use strict;
use warnings;

use Mail::MboxParser;
use Regexp::Common qw/URI/;
use BerkeleyDB;

my $file = "contacts.db" ; 
unlink $file; 

# CONTACTS LIST 
my %CONTACTS = ();
tie %CONTACTS, "BerkeleyDB::Hash",-Filename => $file,-Flags => DB_CREATE or die "Cannot open $file\n" ;

my $mbox= \*STDIN;
my $mb = Mail::MboxParser->new($mbox);

my $id = 1;
my $cId = 1; 

#for my $msg ($mb->get_messages) 
while(my $msg =$mb->next_message) 
{
   my $to = $msg->header->{to};
      $to = removeNewLines($to);

   my $from = $msg->header->{from};
   my @fromArr = matchEmail($from); # return first only - there exists only one FROM 
      $from = shift @fromArr;
   my $from_id = getContactId($from); 

   my $cc = $msg->header->{cc} || " ";
      $cc = removeNewLines($cc);

   my $subject = $msg->header->{subject} || '<No Subject:>';

   my $date = $msg->header->{date};
   my ($week,$month,$day,$year ) = parseDate($date); 

        #print "~" x 77, "\n\n";
	my @to_arr = matchEmail($to); 
	for my $recipient (@to_arr) {
		if(defined $recipient) { 
			my $r_id = getContactId($recipient); 
			print "$id\t$r_id\t$from_id\t$subject\t$year\t$month\t$day\t$week\n";
		}
        }

	#my @cc_arr = split(/[,|;]/,$msg->header->{cc});
	my @cc_arr = matchEmail($cc); 
	for my $recipient (@cc_arr) {
		if(defined $recipient) { 
			my $r_id = getContactId($recipient); 
			print "$id\t$r_id\t$from_id\t$subject\t$year\t$month\t$day\t$week\n";
		}
        }

   my $body = $msg->body($msg->find_body,0);
   my $body_str = $body->as_string || '<No message text>';
   my @arr = split(/\n/,$body_str);

   my $mail_str = "";
   foreach my $sen(@arr) {
	# Skip replied text 
	if($sen=~/^>/) { 
		next;
	}else{
		$mail_str.=$sen." ";
	}
   }
	# remove HTML content 
	$mail_str=~s/\<.+\>//g;
	$mail_str=~s/\s+/ /g;
   #print "Message Text: $mail_str\n";
   #print "\nBookmarks:\n";
$id++;

# TODO: http://search.cpan.org/~vparseval/Mail-MboxParser-0.55/MboxParser/Mail.pm 
# More Metadata
# - Thread-Index
# - Thread-Topic
# - Message ID

# MIME attachments 
# - Save photos 
# - Save Bookmarks | URLS 

# FLAGS 
# - Long Flag, Fwd flag, CC-flag = 0,1,2
# - Forwarded , Replied , Direct email
# - Addressed to me | me in cc | me in bcc 

# STATS 
# - Ratio - Am i one among the hundreds cc'ed ? 
# - Length - of the email vs. response 

}

sub removeNewLines{
	my $inp = shift; 
		$inp=~s/\n/ /g;
		$inp=~s/\r/ /g;
		$inp=~s/\s+/ /g;
	return $inp;
}

sub matchEmail{
	my $inp = shift;
	my @e;
	while($inp=~/([_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4}))/g){
		push(@e,$1);
	}
	return @e;
}

sub matchURL {
	my $inp = shift;
	my @u;
	  while($inp=~m/$RE{URI}{HTTP}{-keep}/g) {
		push(@u,$1);
	  }
	return @u;
}

sub getContactId{
	my $contact= shift; 
	my $id = -1;
		if(!exists $CONTACTS{$contact}){
			$CONTACTS{$contact} = $cId++;
		}
	return $CONTACTS{$contact};
}

sub parseDate {
my $date = shift; 
      $date=~/([A-Za-z]{3}), (\d+?) ([A-Za-z]{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2})/;  # Fri, 18 Jun 2004 01:16:52 -0400
      my $week = $1; 
      my $month = $3; 
      my $day = $2; 
      my $year = $4;
return ($week,$month,$day,$year);
}

