#   @(#) $Id: Defaults.pm,v 1.19 2009/06/17 16:01:05 Frank-Christian_Otto Exp $
# ------------------------------------------------------------------------- #
#
#   RCM - Reliable Configuration Management
#
#   (C) Copyright IBM Corporation 1999,2008
#   All Rights Reserved.
#
# ------------------------------------------------------------------------- #
#
#   SOS - batch tool set
#
# ------------------------------------------------------------------------- #

=pod

=head1 NAME

Susi::Defaults - Default settings for RCM access

=head1 DESCRIPTION

This module provides default settings for RCM access

If RCM user was set to '*' upen first execution, the username will be asked from the called very time. 

=cut

package Susi::Defaults;

use File::Basename;
use Data::Dumper;

use Susi::CommonTools;


my $dbg = 0;			# dump presets and default setting
my $usepresets = 0;		# will be set true if preset file available

%Susi::Defaults::presets = ( 'server'	=> 'rcm.frankfurt.de.sni.ibm.com',
			     'port'	=> '8421',
			     'inst'	=> 'rcm',
			     'user'	=> '',
			     'temp_dir'	=> '',
			     'format'	=> 'stanza',
			     'customer' => '',
			     'password_data' => '',
			     );


my %hex = ( '0'=>0,
	    '1'=>1,
	    '2'=>2,
	    '3'=>3,
	    '4'=>4,
	    '5'=>5,
	    '6'=>6,
	    '7'=>7,
	    '8'=>8,
	    '9'=>9,
	    'A'=>10,
	    'B'=>11,
	    'C'=>12,
	    'D'=>13,
	    'E'=>14,
	    'F'=>15
	    );

sub text2hex($){
    my $data=shift;
    $data=~ s/(.)/sprintf("%02X",ord($1))/eg ;
    return $data;
}

sub hex2text($) {
    my $data=shift;
    $data=~ s/([0-9A-F]{2})/chr(hex($1))/eg ;
    return $data;
}

sub meltData($) {
    my $data=shift;
    my @data=();

    while ($data=~ s/^([0-9A-F]{1})([0-9A-F]{1})// ) {
	my $hi=$hex{$1};
	my $lo=$hex{$2};
	if ($hi&8) {
	    push @data,1;
	} else {
	    push @data,0;
	}
	if ($hi&4) {
	    push @data,1;
	} else {
	    push @data,0;
	}
	if ($hi&2) {
	    push @data,1;
	} else {
	    push @data,0;
	}
	if ($hi&1) {
	    push @data,1;
	} else {
	    push @data,0;
	}
	if ($lo&8) {
	    push @data,1;
	} else {
	    push @data,0;
	}
	if ($lo&4) {
	    push @data,1;
	} else {
	    push @data,0;
	}
	if ($lo&2) {
	    push @data,1;
	} else {
	    push @data,0;
	}
	if ($lo&1) {
	    push @data,1;
	} else {
	    push @data,0;
	}
    }
    $data='';

    my $l=scalar(@data);

    if ($l != 1024) {
	return 'XXXX';
    }
    for (my $index=0;$index<32;$index++) {
	$data.=sprintf("%02X",
		       ($data[0+$index]<< 7)+($data[32+$index]<< 6)+
		       ($data[64+$index]<< 5)+($data[96+$index]<< 4)+
		       ($data[128+$index]<< 3)+($data[160+$index]<< 2)+
		       ($data[192+$index]<< 1)+($data[224+$index]<< 0)
		       );
	$data.=sprintf("%02X",
		       ($data[256+$index]<< 7)+($data[288+$index]<< 6)+
		       ($data[320+$index]<< 5)+($data[352+$index]<< 4)+
		       ($data[384+$index]<< 3)+($data[416+$index]<< 2)+
		       ($data[448+$index]<< 1)+($data[480+$index]<< 0)
		       );
	$data.=sprintf("%02X",
		       ($data[512+$index]<< 7)+($data[544+$index]<< 6)+
		       ($data[576+$index]<< 5)+($data[608+$index]<< 4)+
		       ($data[640+$index]<< 3)+($data[672+$index]<< 2)+
		       ($data[704+$index]<< 1)+($data[736+$index]<< 0)
		       );
	$data.=sprintf("%02X",
		       ($data[768+$index]<< 7)+($data[800+$index]<< 6)+
		       ($data[832+$index]<< 5)+($data[864+$index]<< 4)+
		       ($data[896+$index]<< 3)+($data[928+$index]<< 2)+
		       ($data[960+$index]<< 1)+($data[992+$index]<< 0)
		       );
    }
    return $data;
    
}

sub askitem($$$;$) {
    my $defaults=shift;
    my $item=shift;
    my $question=shift;
    my $allow_empty=shift || 0;
    my $answer='';

    if (exists $defaults->{$item} or $allow_empty) {
	my $def_val = exists $defaults->{$item} ? $defaults->{$item} : '';
	print STDERR "$question [", $def_val, "]:";
	$answer=<STDIN>;
	chomp $answer;
	if ($answer) {
	    $defaults->{$item}=$answer;
	}
    } else {
	while ($answer eq '') {
	    print STDERR "$question:";
	    $answer=<STDIN>;
	    chomp $answer;
	    if ($answer) {
		$defaults->{$item}=$answer;
	    }
	}
    }
}

sub askdefaults($) {
    my $defaults=shift;

    print STDERR "* askdefaults\n" if $dbg;

    unless ($defaults->{'dontask4pwd'}) {
	# dont use default settings from presets
	# ask for
	unless ($usepresets) {
	    askitem($defaults,'server','RCM server');
	    askitem($defaults,'port','RCM server port');
	    askitem($defaults,'inst','RCM instance');
	    askitem($defaults,'user','RCM username');
	    askitem($defaults,'temp_dir',"Temp directory");
	    unless (-d $defaults->{'temp_dir'}) {
		mkdir $defaults->{'temp_dir'};
	    }
	    askitem($defaults,'format',"Format for RCM data");
	    askitem($defaults,'customer',"Customer context", 1);
	}

	if ($defaults->{'user'} eq '*') {
	    $defaults->{'prompt_for_password'} = 'y';
	} else {
	    print STDERR "Do you want\n\t* to be prompted for RCM password every time (y) \n\t* read password from \$SOSPASSWD (e) \n\t* read the password once and store it in defaults (d)\n";
	    
	    while ( $defaults->{'prompt_for_password'} !~ /^(y|e|d)$/ ) {
		askitem($defaults,'prompt_for_password', "please answer y/e/d");
	    }
	    $defaults->{'password'}='';
	    if ($defaults->{'prompt_for_password'} eq 'd') {
		$defaults->{'password'} = get_password($defaults->{'user'});
	    } elsif ($defaults->{'prompt_for_password'} eq 'e') { 
		if ($ENV{SOSPASSWD}) {
		    $defaults->{'password'} = $ENV{SOSPASSWD} ;
		    chomp $defaults->{'password'};
		} else {
		    $defaults->{'prompt_for_password'} = 'y';
		}
	    }
	}

	print STDERR "Settings will be stored in ", $defaults->{'defltfile'}, " for your convenience.\nJust remove this file in case of any problems.\n\n"; 
    } else {
	print STDERR "* ignoring presets\n";
    }

    my $data=$defaults->{'prompt_for_password'};
    $data.='**';
    $data.=$defaults->{'password'};
    $data.='**';
    while (length($data)<128) {
	$data.='+';
    }
    $data=text2hex($data);
    $data=meltData($data);
    
    $defaults->{'password_data'} = $data;

    return 1;
}

sub readdefaults($) {
    my $defaults=shift;
    my $data=$defaults->{'password_data'};
    chomp $data;
    $data=meltData($data);
    $data=hex2text($data);

    if ($data eq 'XXXX') {
	print "* readdefaults: ask defaults and exit\n" if $dbg;
	askdefaults($defaults);
	return 1;
    }
    my @data=split(/\*\*/,$data);

    $defaults->{'prompt_for_password'}=$data[0];
    $defaults->{'password'}=$data[1];

    if ($defaults->{'prompt_for_password'} eq 'e') { 
	if ($ENV{SOSPASSWD}) {
	    $defaults->{'password'} = $ENV{SOSPASSWD} ;
	    chomp $defaults->{'password'};
	} else {
	    $defaults->{'prompt_for_password'} = 'y';
	}
    }
    
    if ($defaults->{'user'} eq '*') {
	askitem($defaults,'user','RCM username');
	$defaults->{'password'} = get_password($defaults->{'user'});
	return 1;
    } else {
	unless ($defaults->{'dontask4pwd'}) {
	    if ($defaults->{'prompt_for_password'} eq 'y') {
		$defaults->{'password'} = get_password($defaults->{'user'});
	    }
	    return 1;
	}
    }
}


sub init($) {
    my $defparams = shift;

    my $os='';
    my $os_type='';
    
    ###my $pwdfile = defined( $defparams->{'password_file'} ) ? 
    	###$defparams->{'password_file'} : '';
    my $defltfile = defined( $defparams->{'config_file'} ) ? 
    	$defparams->{'config_file'} : '';
    
    my %defaults=();
    my ($tmpdir, $confdir);
    my $key;

    if (exists $ENV{'OS'} and $ENV{'OS'}=~ /^windows/i) {
	if ((exists $ENV{'OSTYPE'} and $ENV{'OSTYPE'}=~ /cygwin/i) ||
	    (exists $ENV{'MAKE_MODE'} and $ENV{'MAKE_MODE'}=~ /unix/i) ||
	    (exists $ENV{'TERM'} and $ENV{'TERM'}=~ /cygwin/i) ) {
	    
	    $os_type = 'cygwin';
	} else {
	    $os_type = 'windows';
	}
    } else {
	$os_type = 'unix';
    }

    if ($os_type eq 'windows') {
    	
	$os='WIN';
	
	if ((reverse (split /\\/, dirname($0)))[0] =~ /bin/) {
	    $tmpdir = dirname($0) . '\..\tmp';
	} else {
	    $tmpdir = $ENV{'TEMP'};
	} 
	
	$defaults{'dir_sep'}	= '\\';
	$defaults{'user'}	= $ENV{'USERNAME'};
	$defaults{'home'}	= $ENV{'HOMEDRIVE'}.$ENV{'HOMEPATH'};
	$defaults{'temp_dir'}	= $tmpdir;
	
    } elsif ($os_type eq 'cygwin') {
    	
	$os=`uname -s` unless ($os);
	
	$defaults{'dir_sep'}	= '/';
	$defaults{'user'}	= $ENV{'USER'};
	$defaults{'home'}	= $ENV{'HOME'};
	$defaults{'temp_dir'}	= $defaults{'home'}.'/tmp';
	
    } else {

	$os=`uname -s` unless ($os);
	
	$defaults{'dir_sep'}	= '/';
	$defaults{'user'}	= $ENV{'USER'};
	$defaults{'home'}	= $ENV{'HOME'};
	$defaults{'temp_dir'}	= $defaults{'home'}.'/tmp';
	
    }
    
    # set consistent default configuration directory and files
    $confdir = $defaults{'home'}.$defaults{'dir_sep'}.'.rcm';
    ###$pwdfile='rcm.pwd' unless ($pwdfile);
    $defltfile='rcm.conf' unless ($defltfile);
    
    # create .rcm folder if it does not exist
    mkdir $confdir unless (-d $confdir);
    
    ###$defaults{'pwdfile'}   = $confdir.$defaults{'dir_sep'}.$pwdfile;
    if ($defltfile =~ /[\/\\]/) {
    	# if the complete path is specified: use that path
	$defaults{'defltfile'} = $defltfile;
    } else {
	# otherwise assume the path to confdir = homedir/.rcm/
	$defaults{'defltfile'} = $confdir.$defaults{'dir_sep'}.$defltfile;
	}
    
    if (-f $defaults{'defltfile'}) {
	do $defaults{'defltfile'};
	print STDERR "* init: \%presets\n", Dumper(\%Susi::Defaults::presets), "\n" if $dbg;
	$usepresets = 1;
    } else {
	$usepresets = 0;
    }

    $defaults{'dontask4pwd'} = ( $defparams->{'dontask4pwd'} ) ?
	$defparams->{'dontask4pwd'} : '';

    # load default settings from file/ internal presets
    $defaults{'server'} = $Susi::Defaults::presets{'server'};
    $defaults{'port'}   = $Susi::Defaults::presets{'port'};
    $defaults{'inst'}	= $Susi::Defaults::presets{'inst'};
    $defaults{'user'}   = $Susi::Defaults::presets{'user'} if 
	$Susi::Defaults::presets{'user'};
    $defaults{'temp_dir'} = $Susi::Defaults::presets{'temp_dir'} if 
		$Susi::Defaults::presets{'temp_dir'};
    $defaults{'format'} = $Susi::Defaults::presets{'format'} if 
	$Susi::Defaults::presets{'format'};
    $defaults{'customer'} = $Susi::Defaults::presets{'customer'} if 
	$Susi::Defaults::presets{'customer'};
    $defaults{'password_data'} = $Susi::Defaults::presets{'password_data'} if 
	$Susi::Defaults::presets{'password_data'};
    
    $defaults{'prompt_for_password'} = '';
    $defaults{'password'} = '';
    $defaults{'customer'} = '';

    print STDERR "* init: \%defaults --vorher\n", Dumper(\%defaults), "\n" if $dbg;

    return \%defaults if $defaults{'dontask4pwd'};
    
    # ask for individual changes 
    if ( $usepresets == 0 ) {
	askdefaults(\%defaults);
	
	# store current settings in readable file
	open PF, ">$defaults{'defltfile'}";
	foreach $key (keys %Susi::Defaults::presets) {
	    print STDERR "* init: $key\n" if $dbg;
	    $Susi::Defaults::presets{$key} = $defaults{$key};
	    print PF "\$presets{'",$key,"'} = '",$defaults{$key},"';\n";
	}
	close PF;
    }
    
    $usepresets = 1;
    readdefaults(\%defaults);
    
    print STDERR "* init: \%defaults --nachher\n", Dumper(\%defaults), "\n" if $dbg;
    return \%defaults;
}

1;

