#   @(#) $Id: ExtClientQuery.pm,v 1.11 2011/04/21 14:45:59 Frank-Christian_Otto Exp $
# ------------------------------------------------------------------------- #
#
#   RCM - Reliable Configuration Management
#
#   (C) Copyright IBM Corporation 1999,2004
#   All Rights Reserved.
#
# ------------------------------------------------------------------------- #
#
#   SOS - batch tool set
#
# ------------------------------------------------------------------------- #
#
#   Module:	ExtClientQuery.pm
#
#   Author:	Dr. Frank-Christian Otto (IBM Business Services GmbH)
#
#   Date:	May - 2003
#
#   Purpose:	enlarges ClientQuery.pm
#              + handling of more than one data pool inside one object
#              + other functionality to support comparison of two
#                data sets. used in get_sync_data.pl, process_sync_data.pl
#
# ------------------------------------------------------------------------- #

=pod

=head1 NAME

ExtClientQuery.pm  - extensions to ClientQuery.pm

=head1 SYNOPSIS

    use Susi::ExtClientQuery

=head1 DESCRIPTION

=cut

# ---------------------------------------------------------------------------#
#  here we go...
# ---------------------------------------------------------------------------#

#use File::Basename;
#use lib (dirname($0) . "/../lib"); 


use Carp;
use Susi::Client;
use Susi::ClientQuery;
use Susi::Description;

package Susi::ExtClientQuery;
@ISA = qw( Susi::ClientQuery );

my ($s_rsep, $s_fsep); # record/field separator used by Susi::Client sub object

use strict 'vars';


# ---------------------------------------------------------------------------#
#  SUB new  (constructor method)
# ---------------------------------------------------------------------------#
# 
# uses Susi::ClientQuery->new and adds some structure
#

=head2 new ($susi [,$params])

mandatory arguments: $susi

optional arguments: $params

sample call: $client=Susi::ExtClientQuery->new($susi,{debug =>1})

$susi must be a reference to an already constructed Susi::Client object.
$params is a hash reference. It could be used to set some internal
parameters:

see documentation of Susi::ClientQuery for details about possible parameters.

=cut

# 
#  SUB new  (constructor method)
# ---------------------------------------------------------------------------#
sub new($;$) {
   my $proto = shift;
   my $class = ref $proto || $proto;

   my $susi = shift;
   my $params = shift;

   my $self = $proto->SUPER::new ($susi, $params);
   $s_rsep = $susi->RSEP;
   $s_fsep = $susi->FSEP;
   bless $self, $class;

   # DATA_POOL can store any pool of table data under a name
   $self->{DATA_POOL} = {};
   
   $self->{PK_COLUMNS} = {};

   return $self;
}

# ---------------------------------------------------------------------------#
#  SUB set_data_pool
# ---------------------------------------------------------------------------#
# maps a data pool (stored under  $self->{DATA_POOL})
# to be usuable as  $self->{TABLE_DATA}
#
# as long as a certain data pool is mapped in that way 
# you can use method like
#    collect_table_data
#    sort_columns
#    etc.
# as you are used to do when using Susi::ClientQuery
#
# DANGER! if $self->{TABLE_DATA} contains data that data will be lost!!!
# ---------------------------------------------------------------------------#

#  SUB set_data_pool
# ---------------------------------------------------------------------------#
sub set_data_pool {
    my $self = shift;
    my $pool = shift;

    # TODO generate some run time error if $pool is not defined
    #unless ($pool) 

    # create pool if not existent
    $self->{DATA_POOL}->{$pool} = {} 
    unless (exists $self->{DATA_POOL}->{$pool});

    # set pool
    $self->{TABLE_DATA} = $self->{DATA_POOL}->{$pool};
    print STDERR " * * * switch standard data pool to \"$pool\"\n" 
	if ($self->debug >= 3);
}
# ---------------------------------------------------------------------------#

# ------------------------------------------------------------------------- #
# SUB collect_table_data_to_pool 
# (retrieve data from the database and store it to a specific data pool)
# ------------------------------------------------------------------------- #
#
#   store the result in $self->{DATA_POOL}->{$pool}->{$table}
#   if $pool is not null and in
#   $self->{TABLE_DATA}->{$table} otherwise
#
#   this method corresponds to collec_table_data but it can store data
#   directly to a specific pool without the need to call "set_data_pool"
#

# SUB collect_table_data_to_pool 
# (retrieve data from the database and store it to a specific data pool)
# ------------------------------------------------------------------------- #
sub collect_table_data_to_pool {
    my $self = shift;
    my $pool = shift;
    my $table = shift;
    my $query = shift;
    my $replacement = shift; # reference to a hash of form:
                             #   <column> => <value_to_set>

    if ( (! defined $pool) or (! defined $table) or (! defined $query) ) {
      Carp::carp ("Missing argument in call \"collect_table_data_to_pool\" --- no action \n");
	return;
    }
    my $ptr;
    if ($pool) {
	unless ( exists $self->{DATA_POOL}->{$pool} ) {
	    # silently create not existing data pool
	    $self->{DATA_POOL}->{$pool} = {};
	}
	$ptr = $self->{DATA_POOL}->{$pool};
    } else {
	$ptr = $self->{TABLE_DATA};
    }
    $self->_collect_table_data ($ptr, $table, $query, $replacement);

} # sub collect_table_data_to_pool
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB get_pk_columns
# ------------------------------------------------------------------------- #

=head2  get_pk_columns()

mandatory arguments: 

optional arguments: 

sample call: $client->get_pk_columns ()

=cut

# SUB get_pk_columns
# ------------------------------------------------------------------------- #
# currently we retrieve the pk columns for ANY table listed in
# RCMADM.RCM_TABLES
# this might not be the most efficient way to do it
# ------------------------------------------------------------------------- #
sub get_pk_columns {
    my $self = shift;
    my $owner_added = 0;

    my $ptr = $self->{PK_COLUMNS};

    if ($self->debug >= 3) {
	print STDERR " * * * retrieving primary key columns\n";
    }

    my @temp;
    my ($status, $msg, $query);

    # tables:
    $query = "select table_name from rcmadm.rcm_tables where type = 'TABLE'";
    ($status, $msg) = $self->{SUSI}->query($query);
    Carp::croak("Error reading from RCM -- $msg\nLast action -- $query\n") 
	if ($status != 1403 && $status > 0);
    @temp = split /$s_rsep/, $msg;

    if ($self->debug >= 4) {
	print STDERR " * * * * list of rcm tables of type TABLE:\n";
	foreach (@temp) {
	    print STDERR "\t$_\n";
	}
    }

    foreach my $table (@temp) {
	my ($tab, $owner, $x_tab, $x_owner);

	if ($table =~ m/^([^\.]+)\.([^\.]+)$/) {
	    $x_owner = uc($1); 
	    $x_tab = uc($2);
	} elsif ($table =~ m/^[^\.]+$/) {
	    $x_owner = 'RCM';
	    $x_tab = uc($table);
	    $owner_added = 1;
	} else {
	  Carp::croak("Error -- bad table in rcmadm.rcm_tables: $table");
	}

	# resolve synonyms:
	# try public ones first (cannot be the case if owner was specified
	# initially)
	if ($owner_added or $x_owner eq 'PUBLIC') {
	    $query = "select table_owner, table_name from all_synonyms where owner = 'PUBLIC' and synonym_name = '$x_tab'";
	    ($status, $msg) = $self->{SUSI}->query($query);
	  Carp::croak("Error reading from RCM -- $msg\nLast action -- $query\n") if ($status != 1403 && $status > 0);
	    if ($msg) {
		# we expect just one line
		my ($temp) = (split /$s_rsep/, $msg);
		($owner, $tab) = (split /$s_fsep/, $temp);
	    }
	}
	# if unsuccessful so far: try schema synonyms:
	unless ($owner and $tab) {
	    $query = "select table_owner, table_name from all_synonyms where owner = '$x_owner' and synonym_name = '$x_tab'";
	    ($status, $msg) = $self->{SUSI}->query($query);
	  Carp::croak("Error reading from RCM -- $msg\nLast action -- $query\n") if ($status != 1403 && $status > 0);
	    if ($msg) {
		# we expect just one line
		my ($temp) = (split /$s_rsep/, $msg);
		($owner, $tab) = (split /$s_fsep/, $temp);
	    }
	}
	# if still unsunccessful:
	unless ($owner and $tab) {
	    $owner = $x_owner;
	    $tab = $x_tab;
	}
	
	# read details of primary key constraint
	$query = "select column_name from all_cons_columns " .
         "where owner = '$owner' and table_name = '$tab' and " .
	 "constraint_name = (select constraint_name from all_constraints " .
	 "where owner = '$owner' " .
	 "and table_name = '$tab' and constraint_type = 'P') " . 
         "order by column_name";
	($status, $msg) = $self->{SUSI}->query($query);
      Carp::croak("Error reading from RCM -- $msg\nLast action -- $query\n") 
	  if ($status != 1403 && $status > 0);
	my @cols = ();
	@cols = map {lc($_)} split /$s_rsep/, $msg;
	unless (@cols) {
	  Carp::carp("Error: cannot find pk columns for table $table " .
		      "(wrong type [TABLE] in rcmadm.rcm_tables or insufficient select privileges?)\nLast action -- $query\n");
	    $ptr->{lc($table)} = undef;
	} else {
	    if ($self->debug >= 4) {
		print STDERR " * * * * list of pk columns of table $table:\n";
		foreach (@cols) {
		    print STDERR "\t$_\n";
		}
	    }
	    #
	    $ptr->{lc($table)} = \@cols;
	}
    }

    # views:
    $query = "select table_name from rcmadm.rcm_tables where type = 'VIEW'";
    ($status, $msg) = $self->{SUSI}->query($query);
    Carp::croak("Error reading from RCM -- $msg\nLast action -- $query\n") 
	if ($status != 1403 && $status > 0);
    @temp = split /$s_rsep/, $msg;

    if ($self->debug >= 4) {
	print STDERR " * * * * list of rcm tables of type VIEW:\n";
	foreach (@temp) {
	    print STDERR "\t$_\n";
	}
    }
    foreach my $table (@temp) {

	$query = "select col_name from rcmadm.rcm_views_pk_cols where " .
	    " table_name = '$table'";
	($status, $msg) = $self->{SUSI}->query($query);
      Carp::croak("Error reading from RCM -- $msg\nLast action -- $query\n") 
	  if ($status != 1403 && $status > 0);
	my @cols = ();
	@cols = map {lc($_)} split /$s_rsep/, $msg;
	unless (@cols) {
	  Carp::carp("Error: cannot find pk columns for table $table " .
		      "(wrong type [VIEW] in rcmadm.rcm_tables or missing data in rcmadm.rcm_views_pk_cols?)");
	    $ptr->{lc($table)} = undef;
	} else {
	    if ($self->debug >= 4) {
		print STDERR " * * * * list of pk columns of table $table:\n";
		foreach (@cols) {
		    print STDERR "\t$_\n";
		}
	    }
	    #
	    $ptr->{lc($table)} = \@cols;
	}
    }

    ### TEST
#    foreach (keys %{$ptr}) {
#	print "$_: @{$ptr->{$_}}\n";
#    }

}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB sort_by_pk_columns 
# ------------------------------------------------------------------------- #

=head2  sort_by_pk_columns($src_pool, $dest_pool [, $ins_pool, $upd_pool, $del_pool])

mandatory arguments: $src_pool, $dest_pool 

optional arguments: $ins_pool, $upd_pool, $del_pool

sample call: $client->sort_by_pk_columns("from", "to")

Both mandatory arguments should refer to existing (and already filled) data pools. Then for each table (contained in the union of table list of both pools) we do the following: we sort the table data of both pools using the primary key colums (retrieved before using get_pk_columns) loop over the different values on the pk columns and decide:

A row exists in $src_pool but not in $dest_pool. Then we copy that row from $src_pool to $ins_pool.

A row exists in $dest_pool but not in $src_pool. Then we copy that row from $dest_pool to $del_pool.

A row exists in both pools (according to the values of the pk columns) and the values of all columns equal. Then no action is required.

A row exists in both pools (according to the values of the pk columns) and the some values of non-pk columns differ. Mix both rows to form a suitable update entry to be copied to $upd_pool.

If the optional arguments $ins_pool, $upd_pool, $del_pool are not specified then pools with the default names "ins", "upd", "del" will be used.

=cut

# SUB sort_by_pk_columns 
# ------------------------------------------------------------------------- #
#
#  if some table data (regardless whether in $src_pool or $dest_pool)
#  contains more than one row which match in all pk columns
#  the one coming last will be used for generating inserts/updates/deletes
#
#  advice: make sure that $src_pool, $dest_pool does not contain
#  such contradictive data!
# ------------------------------------------------------------------------- #
sub sort_by_pk_columns {
    my $self = shift;
    my $src_pool = shift;
    my $dest_pool = shift;
    my $ins_pool = shift;
    my $upd_pool = shift;
    my $del_pool = shift;

    my $add_missing_columns = 1;
    my $exact_matching = 1;

    my ($sptr, $dptr);

    # check for existence of both $src_pool and $dest_pool
    unless (defined ($src_pool) and defined ($dest_pool) ) {
      Carp::carp("Error: sort_by_pk_columns: mandatary arguments missing" .
		 " in method call");
	return undef;
    }
    unless (exists ($self->{DATA_POOL}->{$src_pool})) {
      Carp::carp("Error: sort_by_pk_columns: source data pool ($src_pool) does not exist.");
	return undef;
    }
    unless (exists ($self->{DATA_POOL}->{$dest_pool})) {
      Carp::carp("Error: sort_by_pk_columns: destination data pool ($dest_pool) does not exist.");
	return undef;
    }

    # check other pools: either all 3 specified or none
    if (defined ($ins_pool) ) {
	# here we do not discard already existing data 
	# TODO : change this behaviour???
	unless (defined ($upd_pool) and defined ($del_pool) ){
	  Carp::carp("Error: sort_by_pk_columns: either you specify none or all three optional arguments (\"ins_pool\", \"upd_pool\", \"del_pool\")");
	    return undef;
	}
    } else {
	# used default pools
	$ins_pool = "ins";
	if (exists ($self->{DATA_POOL}->{$ins_pool})) {
	  Carp::carp("Error: sort_by_pk_columns: implicitely set insert data pool (\"$ins_pool\") does already exist. Discarding old contents!");
	}
	$self->{DATA_POOL}->{$ins_pool} = {};

	$upd_pool = "upd";
	if (exists ($self->{DATA_POOL}->{$upd_pool})) {
	  Carp::carp("Error: sort_by_pk_columns: implicitely set update data pool (\"$upd_pool\") does already exist. Discarding old contents!");
	}
	$self->{DATA_POOL}->{$upd_pool} = {};

	$del_pool = "del";
	if (exists ($self->{DATA_POOL}->{$del_pool})) {
	  Carp::carp("Error: sort_by_pk_columns: implicitely set update data pool (\"$del_pool\") does already exist. Discarding old contents!");
	}
	$self->{DATA_POOL}->{$del_pool} = {};
    }

    if ($self->debug >= 3) {
	print STDERR " * * * entering sort_by_pk_columns: args:\n";
	print STDERR "\tSOURCE POOL =\"$src_pool\"\n";
	print STDERR "\tDESTINATION POOL =\"$dest_pool\"\n";
 	print STDERR "\tINSERT POOL =\"$ins_pool\"\n";
 	print STDERR "\tUPDATE POOL =\"$upd_pool\"\n";
 	print STDERR "\tDELETE POOL =\"$del_pool\"\n";
   }

    # TODO : check whether get_pk_columns has already run

    # sort columns of $src_pool, $dest_pool w.r.t "select" mode
    $self->set_data_pool ($src_pool);
    $self->_sort_columns ("select", $add_missing_columns);
    $self->set_data_pool ($dest_pool);
    $self->_sort_columns ("select", $add_missing_columns);

    # create some short cuts
    $sptr = $self->{DATA_POOL}->{$src_pool};
    $dptr = $self->{DATA_POOL}->{$dest_pool};
    # switching pools will implicetely create them if necessary
    $self->set_data_pool ($ins_pool);
    $self->set_data_pool ($upd_pool);
    $self->set_data_pool ($del_pool);
    my $ins = $self->{DATA_POOL}->{$ins_pool};
    my $upd = $self->{DATA_POOL}->{$upd_pool};
    my $del = $self->{DATA_POOL}->{$del_pool};

    # build list of tables  from both pools
    my %tables = ();
    foreach my $table (keys %{$sptr}) {
	$tables{$table} = "1";
    }
    foreach my $table (keys %{$dptr}) {
	$tables{$table} = "1";
    }
    my @table_list = sort keys %tables;

    if ($self->debug >=4 ){
	print STDERR " * * * * table list to work on (sort_by_pk_columns):\n";
	foreach (@table_list) {
	    print STDERR "\t$_\n";
	}
    }

    # all black magic takes place in the following loop
    foreach my $table (@table_list) {
	if ($self->debug >= 3) {
	    print STDERR " * * * sort_by_pk_columns: table: $table\n";
	}
	my %s_tab = (); # here we store pk column sorted stuff from $src_pool
	my %d_tab = (); # here we store pk column sorted stuff from $dest_pool

	$sptr = $self->{DATA_POOL}->{$src_pool}->{$table};
	$dptr = $self->{DATA_POOL}->{$dest_pool}->{$table};
	# if $table is not contained in source pool we do not perform
	# any action. (this might generate unexpected delete commands)
	unless ($sptr) {
	    print STDERR " * * * sort_by_pk_columns: no source data for table: $table. Skipping!\n" if ($self->debug >= 3);
	    next;
	}
	# in destination pool a missing table is OK
	#unless ($dptr) {
	#    print STDERR " * * * sort_by_pk_columns: no destination data for table: $table. Skipping!\n" if ($self->debug >= 3);
	#    next;
	#}

	my (@pk_cols, @all_cols, @excl_cols, @cmp_cols);

	unless ( defined ($self->{PK_COLUMNS}->{$table} ) ) {
	  Carp::carp("Error: sort_by_pk_columns: no pk columns for table $table. Skipping!\n");
	    next;
	}
	@pk_cols = @{$self->{PK_COLUMNS}->{$table}};
	@all_cols = $self->_get_column_list ($table, "select");
	# new read exclude columns from database
	@excl_cols = $self->_get_excl_columns ($table);
	# for comparision we need @cmp_cols which is the @all_cols
	# minus @excl_cols:
	my %temp = ();
	@cmp_cols = ();
	foreach (@excl_cols) {
	    $temp{$_} = "";
	}
	foreach (@all_cols) {
	    push (@cmp_cols, $_) unless (exists ($temp{$_}));
	}

	if ($self->debug >= 4) {
	    print STDERR " * * * * pk column list for table: $table\n";
	    foreach (@pk_cols) {
		print STDERR "\t$_\n";
	    }
	}
	#if ($self->debug >= 4) {
	#    print STDERR " * * * * complete column list for table: $table\n";
	#    foreach (@all_cols) {
	#	print STDERR "\t$_\n";
	#    }
	#}
	#if ($self->debug >= 4) {
	#    print STDERR " * * * * exclude column list for table: $table\n";
	#    foreach (@excl_cols) {
	#	print STDERR "\t$_\n";
	#    }
	#}
	if ($self->debug >= 4) {
	    print STDERR " * * * * compare column list for table: $table\n";
	    foreach (@cmp_cols) {
		print STDERR "\t$_\n";
	    }
	}

	my ($pk_col_data, $all_col_data);
	# work on $src_pool for table $table
	if ($sptr) {
	    for (my $i = 0; $i <= $#{$sptr}; $i++ ) {
		$pk_col_data = 
		    $self->_prepare_select_columns ($sptr->[$i], 
						    $add_missing_columns, 
						    $exact_matching, 
						    @pk_cols);
		$all_col_data = 
		    $self->_prepare_select_columns ($sptr->[$i], 
						    $add_missing_columns, 
						    $exact_matching, 
						    @all_cols);
		$s_tab{$pk_col_data} = $all_col_data;
	    }
	}
	if ($self->debug >= 4) {
	    print STDERR " * * * * \"pk column\" sorted source data of table: $table\n";
	    foreach my $key (keys %s_tab) {
		print STDERR "\t$key => $s_tab{$key}\n";
	    }
	}
	# TODO  : here we have the same code again. some more clever is called for
	# work on $dest_pool for table $table
	if ($dptr) {
	    for (my $i = 0; $i <= $#{$dptr}; $i++ ) {
		$pk_col_data = 
		    $self->_prepare_select_columns ($dptr->[$i], 
						    $add_missing_columns, 
						    $exact_matching, 
						    @pk_cols);
		$all_col_data = 
		    $self->_prepare_select_columns ($dptr->[$i], 
						    $add_missing_columns, 
						    $exact_matching, 
						    @all_cols);
		$d_tab{$pk_col_data} = $all_col_data;
	    }
	}
	if ($self->debug >= 4) {
	    print STDERR " * * * * \"pk column\" sorted destination data of table: $table\n";
	    foreach my $key (keys %d_tab) {
		print STDERR "\t$key => $d_tab{$key}\n";
	    }
	}
	
	# new we sort things out (for table $table)
	# 1. find necessary deletes
	foreach my $key (keys %d_tab ) {
	    unless (exists ($s_tab{$key} ) ) {
		if ($self->debug >= 4) {
		    print STDERR " * * * * delete action detected for:\n";
		    print STDERR "\t$key\n";
		}
		# $key (pair of pk-column/value pairs) does not occur
		# in $src_pool for table $table ==>
		# corresponding row of $dest_pool will be copied to $del_pool
		$del->{$table} = [] 
		    unless (defined ($del->{$table}));
		push (@{$del->{$table}}, $d_tab{$key});
	    }
	}
	# 2. find necessary inserts/updates
	foreach my $key (keys %s_tab ) {
	    if (exists ($d_tab{$key} ) ) {
		if ($self->debug >= 4) {
		    print STDERR " * * * * possible update action detected for:\n";
		    print STDERR "\t$key\n";
		}
		# ok, data contained both in $src_pool and $dest_pool
		# check whether update is necessary
		unless ( $s_tab{$key} eq $d_tab{$key} ) {
		    # ok, data is different, but we have to look at
		    # @cmp_cols only:
		    my ($sdata, $ddata);
		    $sdata = $self->_prepare_select_columns ($s_tab{$key}, 
						    !$add_missing_columns, 
						    $exact_matching, 
						    @cmp_cols);
		    $ddata = $self->_prepare_select_columns ($d_tab{$key}, 
						    !$add_missing_columns, 
						    $exact_matching, 
						    @cmp_cols);
		    next if ($sdata eq $ddata); # only irrelevant columns differ

		    if ($self->debug >= 4) {
			print STDERR "\tupdate action confirmed\n";
		    }
		    # 2a. some values seem to differ ==>
		    # corresponding rows of $src_pool and $dest_pool 
		    # should be merged to form and update record to be 
		    # stored in $upd_pool
		    # in most cases it is sufficient to simple copy
		    # the row from $src_pool to $upd_pool and sort
		    # $upd_pool using "update" mode later.
		    # This is not 100% safe but we are willing to take
		    # the risk:
		    $upd->{$table} = [] 
			unless (defined ($upd->{$table}));
		    push (@{$upd->{$table}}, $s_tab{$key});

		}
	    } else {
		if ($self->debug >= 4) {
		    print STDERR " * * * * insert action detected for:\n";
		    print STDERR "\t$key\n";
		}
		# 2b. row not contained in $dest_pool ==>
		# corresponding row of $src_pool will be copied to $ins_pool
		$ins->{$table} = [] 
		    unless (defined ($ins->{$table}));
		push (@{$ins->{$table}}, $s_tab{$key});
		 
	    }
	}
    } # foreach my $table (@table_list)

    # sort each output data pool:
    $self->set_data_pool ($ins_pool);
    $self->sort_columns ("insert");
    if ($self->debug >= 4) {
	print STDERR " * * * * contents of insert pool:\n";
	my @buffer = $self->print_table_data ("plain");
	foreach (@buffer) {
	    print STDERR "\t$_\n";
	}
    }
    $self->set_data_pool ($upd_pool);
    # for "update" we need $add_missing_column functionality here ???
    $self->_sort_columns ("update", $add_missing_columns);
    if ($self->debug >= 4) {
	print STDERR " * * * * contents of update pool:\n";
	my @buffer = $self->print_table_data ("plain");
	foreach (@buffer) {
	    print STDERR "\t$_\n";
	}
    }
    $self->set_data_pool ($del_pool);
    $self->sort_columns ("delete");
    if ($self->debug >= 4) {
	print STDERR " * * * * contents of delete pool:\n";
	my @buffer = $self->print_table_data ("plain");
	foreach (@buffer) {
	    print STDERR "\t$_\n";
	}
    }
    # switch std data pool back to $src_pool (just for fun)
    $self->set_data_pool ($src_pool);
    
    
}
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SUB _get_excl_columns
# ------------------------------------------------------------------------- #

=head2  _get_excl_columns ($table)

mandatory arguments: $table

optional arguments: 

sample call: $client->_get_excl_columns ("my_table")

=cut

# SUB _get_excl_columns
# ------------------------------------------------------------------------- #
# data comes from RCMADM.RCM_SYNC_EXCL_COLS
# ------------------------------------------------------------------------- #
sub _get_excl_columns {
    my $self = shift;
    my $table = shift;

    my @result = ();

    return @result unless ($table);

    my @temp;
    my ($status, $msg, $query);

    $table = uc($table); # upper case needed for query!
    $query = "select col_name from rcmadm.rcm_sync_excl_cols where table_name = '$table'";
    ($status, $msg) = $self->{SUSI}->query($query);
    Carp::croak("Error reading from RCM -- $msg\nLast action -- $query\n") 
	if ($status != 1403 && $status > 0);
    @temp = split /$s_rsep/, $msg;

    foreach (@temp) {
	push (@result, lc($_)); # lower case for later comparison
    }

    return @result;
}
# ------------------------------------------------------------------------- #

1;

__END__

# ------------------------------------------------------------------------- #
# more POD 
# ------------------------------------------------------------------------- #

=head1 SEE ALSO

Susi::Client
Susi::Description
Susi::ClientQuery

=head1 AUTHOR

Frank-Christian Otto, IBM Business Services GmbH <Frank-Christian.Otto@de.ibm.com>

S<(C) Copyright IBM Corporation 2000,2004>

=cut
