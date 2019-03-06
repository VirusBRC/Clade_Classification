#!/bin/bash
#################################################################################
#
# Setup the oracle environment for Perl access via DBI
#
# (These exports only need to be here if the environmnet has not already exported
#  these variables)
#
#################################################################################

export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_1
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH

#################################################################################
#
# Setup the Perl Environment
#
#################################################################################

export PERL_SW_ROOT=/home/idaily/perl
export LIB_ROOT=$PERL_SW_ROOT/pipelines_sw/pipelines/lib
export BIN_ROOT=$PERL_SW_ROOT/pipelines_sw/pipelines/bin
export CONFIG_ROOT=/home/idaily/influenza_daily/config
export PERL5LIB=$CONFIG_ROOT:$LIB_ROOT

#################################################################################
#
# Setup the python and taxit Path
#
#################################################################################

export PATH=/usr/local/bin:$PATH

################################################################################
