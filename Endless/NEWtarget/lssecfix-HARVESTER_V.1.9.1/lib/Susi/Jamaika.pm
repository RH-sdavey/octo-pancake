# $Id: Jamaika.pm,v 1.1 2006/08/25 13:21:46 Andreas_Jung1 Exp $
#----------------------------------------------
# Copyright: (c) IBM Business Services
# Author: Radoslaw Wierzbicki
#----------------------------------------------
#


package Jamaika;

use strict;

use LWP;
use URI;
use URI::QueryParam;
use HTTP::Request;
use HTTP::Request::Common;

our $VERSION = "1.00";

my $dbg = 0;
#eval ('use Data::Dumper; 1;') if $dbg;

##############################
sub new {
    my ($this, $params) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    if (defined($params->{'jamaika_url'})) {
        $self->{'jamaika_url'} = $params->{'jamaika_url'};
    } else {
        print('Jamaika error: jamaika_url parameter not set');
        return undef;
    }
    $self->{'rcm_user'}     = $params->{'rcm_user'};
    $self->{'rcm_password'} = $params->{'rcm_password'};
    $dbg = $params->{'debug'} || 0;
    bless $self, $class;
    return $self;
}

##############################
sub get_file {
    my ($self, $params) = @_;
    my $uri = new URI($self->{'jamaika_url'});
    $uri->path('/blob/read/appl_file/appl_file');
    $uri->query_param('hostid'   => $params->{'hostid'});
    $uri->query_param('service'  => $params->{'service'});
    $uri->query_param('function' => $params->{'function'});
    $uri->query_param('filename' => $params->{'filename'});
    return _get_request($self, {'uri' => $uri, 'auth' => 1});
}

##############################
sub put_file {
    my ($self, $params) = @_;
    my $uri = new URI($self->{'jamaika_url'});
    $uri->path('/blob/write/appl_file');
    my $content = [
        'hostid'      => $params->{'hostid'},
        'service'     => $params->{'service'},
        'function'    => $params->{'function'},
        'filename'    => $params->{'filename'},
        'description' => $params->{'description'} ? $params->{'description'} : '',
        'appl_file'   => $params->{'file_content'},
    ];
    return _post_request($self,
        {'uri' => $uri, 'content' => $content, 'auth' => 1});
}

##############################
sub delete_file {
    my ($self, $params) = @_;
    my $uri = new URI($self->{'jamaika_url'});
    $uri->path('/blob/delete/appl_file');
    $uri->query_param('hostid'   => $params->{'hostid'});
    $uri->query_param('service'  => $params->{'service'});
    $uri->query_param('function' => $params->{'function'});
    $uri->query_param('filename' => $params->{'filename'});
    return _get_request($self, {'uri' => $uri, 'auth' => 1});
}

##############################
sub get_template {
    my ($self, $params) = @_;
    my $uri = new URI($self->{'jamaika_url'});
    $uri->path('/blob/read/appl_template/appl_template');
    $uri->query_param('service'  => $params->{'service'});
    $uri->query_param('function' => $params->{'function'});
    $uri->query_param('filename' => $params->{'filename'});
    return _get_request($self, {'uri' => $uri, 'auth' => 1});
}

##############################
sub put_template {
    my ($self, $params) = @_;
    my $uri = new URI($self->{'jamaika_url'});
    $uri->path('/blob/write/appl_template');
    my $content = [
        'service'     => $params->{'service'},
        'function'    => $params->{'function'},
        'filename'    => $params->{'filename'},
        'description' => $params->{'description'} ? $params->{'description'} : '',
        'appl_template'   => $params->{'file_content'},
    ];
    return _post_request($self,
        {'uri' => $uri, 'content' => $content, 'auth' => 1});
}

##############################
sub delete_template {
    my ($self, $params) = @_;
    my $uri = new URI($self->{'jamaika_url'});
    $uri->path('/blob/delete/appl_template');
    $uri->query_param('service'  => $params->{'service'});
    $uri->query_param('function' => $params->{'function'});
    $uri->query_param('filename' => $params->{'filename'});
    return _get_request($self, {'uri' => $uri, 'auth' => 1});
}

##############################
sub get_file_list {
    my ($self, $params) = @_;
    my $uri = new URI($self->{'jamaika_url'});
    $uri->path('/blob/select/appl_file');
    $uri->query_param(
        'select' => 'hostid,service,function,filename,description');
    $uri->query_param('hostid'   => $params->{'hostid'});
    $uri->query_param('service'  => $params->{'service'}) 
	if $params->{'service'};
    $uri->query_param('function' => $params->{'function'}) 
	if $params->{'function'};
    my $file = _get_request($self, {'uri' => $uri, 'auth' => 0});
    my $records = [];
    my $record = {};
    if (defined($file)) {
        foreach my $line (@{$file}) {
	    print STDERR "* $line\n" if $dbg;
	    $record = {} if ($line =~ /<TableRow/);
            if ($line =~ /\s+<Column name=\"FILENAME\">(.+)<\/Column>/) {
		${$record}{filename} = $1;
            }
            if ($line =~ /\s+<Column name=\"SERVICE\">(.+)<\/Column>/) {
		${$record}{service} = $1;
            }
            if ($line =~ /\s+<Column name=\"FUNCTION\">(.+)<\/Column>/) {
		${$record}{function} = $1;
            }
	    push(@{$records}, $record) if ($line =~ /<\/TableRow/);
        }
    }
    return $records;
}

##############################
sub get_template_list {
    my ($self, $params) = @_;
    my $uri = new URI($self->{'jamaika_url'});
    $uri->path('/blob/select/appl_template');
    $uri->query_param('select'   => 'service,function,filename,description');
    $uri->query_param('service'  => $params->{'service'})
	if $params->{'service'};
    $uri->query_param('function' => $params->{'function'})
	if $params->{'function'};
    my $file = _get_request($self, {'uri' => $uri, 'auth' => 0});
    my $records = [];
    my $record = {};
    if (defined($file)) {
        foreach my $line (@{$file}) {
	    print STDERR "* $line\n" if $dbg;
	    $record = {} if ($line =~ /<TableRow/);
            if ($line =~ /\s+<Column name=\"SERVICE\">(.+)<\/Column>/) {
		${$record}{service} = $1;
            }
            if ($line =~ /\s+<Column name=\"FUNCTION\">(.+)<\/Column>/) {
		${$record}{function} = $1;
            }
            if ($line =~ /\s+<Column name=\"FILENAME\">(.+)<\/Column>/) {
		${$record}{filename} = $1;
            }
	    push(@{$records}, $record) if ($line =~ /<\/TableRow/);
        }
    }
    return $records;
}

##############################
sub _get_request {
    my ($self, $params) = @_;

    if (!defined($params->{'uri'})) {
        croak('uri parameter not defined');
    }

    my $hdrs = new HTTP::Headers();
    if ($params->{'auth'}) {
        if (!defined($self->{'rcm_user'})) {
            print('Jamaika error: rcm_user parameter not defined');
            return undef;
        }
        if (!defined($self->{'rcm_password'})) {
            print('Jamaika error: rcm_password parameter not defined');
            return undef;
        }
        $hdrs->authorization_basic($self->{'rcm_user'},
            $self->{'rcm_password'});
    }

    my $req = new HTTP::Request('GET', $params->{'uri'}, $hdrs);

    print STDERR "* ", $req->as_string(), "\n" if $dbg;

    my $ua = new LWP::UserAgent;
    $ua->timeout(15);
    my $res = $ua->request($req);
    if ($res->is_success) {
        my @outarray = split("\n", ${$res->content_ref});
        return \@outarray;
    } else {
        print('Jamaika error: ' . $res->status_line() . "\n");
        return undef;
    }
}

##############################
sub _post_request {
    my ($self, $params) = @_;

    if (!defined($params->{'uri'})) {
        croak('uri parameter not defined');
    }

    my $hdrs = new HTTP::Headers();
    if ($params->{'auth'}) {
        if (!defined($self->{'rcm_user'})) {
            print('Jamaika error: rcm_user parameter not defined');
            return undef;
        }
        if (!defined($self->{'rcm_password'})) {
            print('Jamaika error: rcm_password parameter not defined');
            return undef;
        }
        $hdrs->authorization_basic($self->{'rcm_user'},
				   $self->{'rcm_password'});
    }

    my $req = HTTP::Request::Common::POST(
        $params->{'uri'},
        'Content_Type'  => 'multipart/form-data',
        'Content'       => $params->{'content'},
        'Authorization' => $hdrs->header('Authorization'),
    );

    print STDERR "* ", $req->as_string(), "\n" if $dbg;

    my $ua = new LWP::UserAgent;
    $ua->timeout(15);

    print STDERR "* sending request...\n" if $dbg;

    my $res = $ua->request($req);
    if ($res->is_success) {
        my @outarray = split("\n", ${$res->content_ref});
        return \@outarray;
    } else {
        print('Jamaika error: ' . $res->status_line() . "\n");
        return undef;
    }
}

##############################
1;

# -*-perl-*-
# vim:ai:et:ts=4:sw=4

__END__

=head1 NAME

Jamaika - perl module implementing Jamaika functionality

=head1 SYNOPSIS

    use Jamaika;
    my $jamaika = new Jamaika(
        {   'jamaika_url'  => 'http://rcm.frankfurt.de.sni.ibm.com:8080',
            'rcm_user'     => 'abc100',
            'rcm_password' => 'password',
        }
    );
    if (defined($jamaika)) {
        my $filenames = $jamaika->get_file_list(
            {   'hostid'   => 'machinenameinrcm',
                'service'  => 'Apache',
                'function' => 'http',
            }
        );
        foreach my $filename (@{$filenames}) {
            print("$filename\n");
        }
    }

=head1 DESCRIPTION

This module implements methods of retrieving list of files, files, and saving
files to RCM database using HTTP protocol.

This module presents the OO interface.

Parameters to all methods are passed as key-value pairs in an annonymous hash:

    my $filecontent = $jamaika->get_file(
        {   'hostid'   => 'machinenameinrcm',
            'service'  => 'Apache',
            'function' => 'http',
            'filename' => 'www:httpd.conf',
        }
    );

All functions return an array reference.

=head1 CONSTRUCTOR

The constructor expects an annonymous array with the following keys:

    jamaika_url  - url in form http://hostname:port
    rcm_user     - optional for listing methods
    rcm_password - optional for listing methods
    
    my $jamaika = new Jamaika(
        {   'jamaika_url'  => 'http://rcm.frankfurt.de.sni.ibm.com:8080',
            'rcm_user'     => 'abc100',
            'rcm_password' => 'password',
        }
    );

On failure it returns I<undef>.

=head1 FUNCTIONS

=over 4

=item get_file_list(hash_ref)

Retrievs a list of filenames for a specific host, service, and function.
Filenames are returned in array reference. Allowed parameter keys are:

    hostid
    service
    function

This method does not need authentication. On failure it returns I<undef>.

=item get_template_list(hash_ref)

Retrievs a list of template names for a specific service, and function.
Templatenames are returned in array reference. Required parameter keys are:

    service
    function

This method does not need authentication. On failure it returns I<undef>.

=item get_file(hash_ref)

Retrieves a file from APPL_FILE and returns array reference.
Required parameter keys are:

    hostid
    service
    function
    filename

This method requires authentication. On failure it returns I<undef>.

=item get_template(hash_ref)

Retrieves a template from APPL_TEMPLATE and returns array reference.
Required parameter keys are:

    service
    function
    filename

This method requires authentication. On failure it returns I<undef>.

=item delete_file(hash_ref)

Deletes a file from APPL_FILE.
Required parameter keys are:

    hostid
    service
    function
    filename

This method requires authentication. On failure it returns I<undef>.

=item delete_template(hash_ref)

Deletes a template from APPL_TEMPLATE.
Required parameter keys are:

    service
    function
    filename

This method requires authentication. On failure it returns I<undef>.

=item put_file(hash_ref)

Saves a file in APPL_FILE. File to be saved must exist in the filesystem and its
name is passed as one of the parameters.
Required parameter keys are:

    hostid
    service
    function
    filename
    description (optional)
    file

This method requires authentication. On failure it returns I<undef>.

    my $out = $jamaika->put_file(
        {   'hostid'   => 'machinenameinrcm',
            'service'  => 'Apache',
            'function' => 'http',
            'filename' => 'www:httpd.conf',
            'file'     => ['/tmp/httpd.conf'],
        }
    );

=item put_template(hash_ref)

Saves a file in APPL_TEMPLATE. File to be saved must exist in the filesystem
and its name is passed as one of the parameters.
Required parameter keys are:

    service
    function
    filename
    description (optional)
    file

This method requires authentication. On failure it returns I<undef>.

    my $out = $jamaika->put_template(
        {   'service'  => 'Apache',
            'function' => 'http',
            'filename' => 'HTTP',
            'file'     => ['/tmp/httpd.conf'],
        }
    );

=back

=head1 AUTHOR, VERSION, COPYRIGHT

Radoslaw Wierzbicki

Copyright 2006, IBM Business Services GmBH. All Rights Reserved.

=cut
