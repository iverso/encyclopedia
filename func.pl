# Overall functions for Encyclopedia project


if(!$force){
  print "\nMatrix has you...";
}else{

# Libs
use DBI;
use CGI;
use Switch;
use CGI::Session;
use CGI qw(:standard);

# $_POST definition
$p = new CGI;

$data{"email"} = $p->param('email');
$data{"pass"} = $p->param('pass');

#############################################################################


#-------------
#@@ overall@@#
#-------------


# Connect to database
sub connect {
  $user ="iversopro9";
  $password ="encyclopedia789";
  $database ="iversopro9";
  $hostname ="localhost";
  $driver = "mysql";
  $conf = "DBI:$driver:database=$database;host=$hostname;";
  
  $db = DBI->connect($conf, $user, $password);
  $q = $db->prepare("SET NAMES 'utf8'");
  $q->execute();
}

#extracting uri to array
sub extract_uri{
	my $uri = $ENV{'REQUEST_URI'};
	@uris = split ('/', $uri);
	return @uris;
}

#Make hash
sub mhash {
	use Digest::SHA qw(sha1_hex);
	return sha1_hex("sol".$_[0]."los");
}

#slug creator
sub mslug {
  my ($string) = @_;
  $string = lc($string);
  $string =~ s/ń/n/;
  $string =~ s/ć/c/;
  $string =~ s/ź/z/;
  $string =~ s/ż/z/;
  $string =~ s/ł/l/;
  $string =~ s/ą/a/;
  $string =~ s/ó/o/;
  $string =~ s/ś/s/;
  $string =~ s/ę/e/;
  $string =~ s/[-\s]+/-/g;
  return $string;
}

#Header switcher
sub prhead{
  
  if($logged){
    switch (@uris[1]) {
      case "w"  {require "/header-m.pl";}
      case "e"  {require "/header-m.pl";}
      case "d"  {require "/header-m.pl";}
      case "a"  {require "/header-m.pl";}
      else     {require "/header-d.pl";}
    }
  } else {
    require "/header-d.pl";
  }
}

#Count word in library
sub wordcount{
  $q = $db->prepare("SELECT COUNT(id) AS ile FROM words");
	$q->execute();
	my $r = $q->fetchrow_hashref();
  return $r->{"ile"};
}


#------------
#@@ index @@#
#------------


# Check is logged
sub checklogged {
	my $rc = cookie('encyclopedia');
	$session = new CGI::Session(undef, $rc, {Directory=>"/tmp"});
	if($session->param("id")){
		$logged = 1;
		
		#Keeping session (add + 10 minutes)
		my $cookie = cookie(
		-name=>'encyclopedia',
		value=>$session->id,
		-expires=>'+10m');
		print header(-cookie=>$cookie, -charset=>"utf-8");
	} else {
		$logged = 0;
		$session->delete();
	}
}

#Manage includes (by $_GET from .htaccess)
sub includer{

  switch (@uris[1]) {
    case "w"  {require "word.pl";}
    case "e"  {require "edit.pl";}
    case "d"  {require "delete.pl";}
    case "a"  {require "add.pl";}
    else     {require "main.pl";}
  }
  
}

#Start session after valid data
sub start_ses {
  if(!$logged){
	$session = new CGI::Session(undef, undef, {Directory=>"/tmp"});
	$session->param("id", $_[0]);
	$session->param("user", $_[1]);

  my $cookie = cookie(
	-name=>'encyclopedia',
	value=>$session->id,
	-expires=>'+10m');
  print header(-cookie=>$cookie, -charset=>"utf-8");

	$logged = 1;
	}
}

#Logoff
sub req_logout {
	$session->delete();
	$status = "Wylogowano";
	$logout = "success";
	$logged = 0;
}


#---------------
#@@ add/edit @@#
#---------------


#removing duplicates entry
sub rem_dup{
	my @tmparr = @_[0];
	my %hash = map { $_ => 1 } @tmparr;
	@uniq = keys %hash;
	return @uniq;
}

#Validating entered data
sub req_login {
		
		$q = $db->prepare("SELECT id, CONCAT(name,' ',surname) as user FROM users WHERE email='".$data{"email"}."' AND pass='".mhash($data{"pass"})."' ");
		$q->execute();
		my $r = $q->fetchrow_hashref();
		if($r->{"id"}){
			start_ses($r->{"id"},$r->{"user"});
		} else {
			$status = "Zły login / hasło!";
		}
		$q->finish();
		
}

#Check existing word if modify word name
sub chk_ex_wr {
  $q = $db->prepare("SELECT * FROM words WHERE (word LIKE '".$_[0]."') ");
	$q->execute();
	my $res = $q->fetchrow_hashref();
	if($res->{"id"}) {return 1;}
	else {return 0;}
}


#------------
#@@ main @@#
#------------


#Searcher
sub req_search {
  if(!$p->param('search')) {
    print "<div class='sm-bar'>Witaj w Encyklopedii! Skorzystaj z powyższej wyszukiwarki w celu odnalezienia słowa które Cię interesuje.</div>";
  } else {
    print "<div class='search_result'><ul>";
    $q = $db->prepare("SELECT * FROM words WHERE (word LIKE '%".$p->param('search')."%') OR (description LIKE '%".$p->param('search')."%') ");
    $q->execute();
    
    $i=0;
    while (my $res = $q->fetchrow_hashref()){
      $i++;
      print "<li><div class='cont'><a class='wrd' title='Przejdź do wybranego słowa' href='/w/".$res->{'id'}."/".$res->{'slug'}."'><b>".$res->{'word'}."</b> - <i>".substr($res->{'description'},0,95)."...</i></a></div><div class='func'><a title='Edytuj' class='edit' href='/e/".$res->{'id'}."/".$res->{'slug'}."'></a><a title='Usuń' class='del' href='/d/".$res->{'id'}."'></a></div><div class='clear'></div></li>";
    }
    
    if(!$i) {
      print "<div class='status-info' style='width: 450px; margin: 15px auto 0px auto;'>Słowo nie zostało odnalezione</div>";
    }
    
    print "</ul></div>";
  }
}



}
1;