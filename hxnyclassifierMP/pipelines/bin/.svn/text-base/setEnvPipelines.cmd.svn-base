#!/bin/bash
#################################################################################
#
# Setup the oracle environment for Perl access via DBI
#
#################################################################################

export ORACLE_BASE=/home/oracle/app/oracle/product/11.2.0/client_1
export ORACLE_HOME=/home/oracle/app/oracle/product/11.2.0/client_1
export PATH=$ORACLE_HOME/bin:/usr/kerberos/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH

#################################################################################
#
# Setup Perl environment
#
#################################################################################

export PERL_SW_ROOT=/home/dbadmin/perl
export LIB_ROOT=$PERL_SW_ROOT/pipelines_sw/pipelines/lib
export BIN_ROOT=$PERL_SW_ROOT/pipelines_sw/pipelines/bin
export CONFIG_ROOT=/home/dbadmin/<--RUN-TYPE-->/config
export PERL5LIB=$CONFIG_ROOT:$LIB_ROOT

#################################################################################
#
# Setup Blast
#
#################################################################################

export PATH=/home/dbadmin/loader/ext/blast-2.2.15/bin:$PATH

#################################################################################
#
# Setup R
#
#################################################################################

export R_HOME=/home/dbadmin/bin/lib64/R
export PATH=$R_HOME/bin:$PATH

#################################################################################
#
# Setup Java environment
#
#################################################################################

export JAVA_HOME=/home/dbadmin/loader/ext/jdk1.5.0_06
export PATH=$JAVA_HOME/bin:$PATH
export PIPELINE_LIB=/home/dbadmin/bin/rate4site/lib
export CLASSPATH=$CLASSPATH:$PIPELINE_LIB:.
