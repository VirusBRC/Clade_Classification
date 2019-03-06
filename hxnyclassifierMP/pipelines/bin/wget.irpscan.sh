#!/bin/bash

root="$1"

user="ftp"
passwd="anonymous"
/bin/rm -rf $root
mkdir $root
cd $root
a_log="$root/wget.log"
root_url="ftp://ftp.ebi.ac.uk/pub/software/unix/iprscan"

urls="ACKNOWLEDGEMENTS FAQs.txt Installing_InterProScan.txt NEWS README.txt ReleaseNotes.txt index.html"
for url in $urls
do
  wget -a $a_log -P $root --progress=dot:mega --http-user=$user --http-passwd=$passwd -nd -nH -N "$root_url/$url"
done
echo "Done TOP"
###
### Release
###
urls="README 4.8/iprscan_v4.8.tar.gz"
for url in $urls
do
  wget -a $a_log -P $root --progress=dot:mega --http-user=$user --http-passwd=$passwd -nd -nH -N "$root_url/RELEASE/$url"
done
mv $root/README $root/README.RELEASE
echo "Done RELEASE"
###
### Bin
###
urls="README 4.x/iprscan_bin4.x_Linux64.tar.gz"
for url in $urls
do
  wget -a $a_log -P $root --progress=dot:mega --http-user=$user --http-passwd=$passwd -nd -nH -N "$root_url/BIN/$url"
done
mv $root/README $root/README.BIN
echo "Done BIN"
###
### Data
###
urls="README iprscan_MATCH_DATA_35.0.tar.gz iprscan_DATA_35.0.tar.gz iprscan_PTHR_DATA_31.0.tar.gz"
for url in $urls
do
  wget -a $a_log -P $root --progress=dot:mega --http-user=$user --http-passwd=$passwd -nd -nH -N "$root_url/DATA/$url"
done
mv $root/README $root/README.DATA
echo "Done DATA"
echo"DONE All"
