#!/bin/bash
#################################################################################
#
# Now setup the oracle environment for Perl access via DBI
#
#################################################################################

export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/11.2.0/dbhome_1
export PATH="/home/dbadmin/loader/ext/blast-2.2.15/bin:/home/dbadmin/bin/orthomcl/bin:$ORACLE_HOME/bin:$ORACLE_HOME/lib:$PATH"
export LD_LIBRARY_PATH="$ORACLE_HOME/lib:$LD_LIBRARY_PATH"

#################################################################################
#
# Now setup the Perl environment
#
#################################################################################

export PERL_SW_ROOT=/home/dbadmin/perl
export LIB_ROOT=$PERL_SW_ROOT/pipelines_sw/pipelines/lib
export BIN_ROOT=$PERL_SW_ROOT/pipelines_sw/pipelines/bin
export CONFIG_ROOT=/home/dbadmin/orthomcl/config
export PERL5LIB=$CONFIG_ROOT:$LIB_ROOT

################################################################################
