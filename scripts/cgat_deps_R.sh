#!/usr/bin/env bash
#
# Script to find R deps in this repository
#
# It simply looks for the 'library(' statement in the source code
#

SCRIPT_FOLDER=$(dirname $0)
REPO_FOLDER=$(dirname ${SCRIPT_FOLDER})
TMP_GREP=$(mktemp)
TMP_DEPS=$(mktemp)

declare -A DEPS
DEPS[Biobase]="bioconductor-biobase"
DEPS[DESeq]="bioconductor-deseq"
DEPS[DESeq2]="bioconductor-deseq2"
DEPS[DEXSeq]="bioconductor-dexseq"
DEPS[HilbertVis]="bioconductor-hilbertvis"
DEPS[IHW]="bioconductor-ihw"
DEPS[MEDIPS]="bioconductor-medips"
DEPS[RColorBrewer]="r-rcolorbrewer"
DEPS[VennDiagram]="r-venndiagram"
DEPS[WGCNA]="r-wgcna"
DEPS[biomaRt]="bioconductor-biomart"
DEPS[coloc]="r-coloc"
DEPS[database]="ignore"
DEPS[edgeR]="bioconductor-edger"
DEPS[flashClust]="r-flashclust"
DEPS[genome_file]="ignore"
DEPS[ggplot2]="r-ggplot2"
DEPS[gplots]="r-gplots"
DEPS[grid]="r-gridbase"
DEPS[gridExtra]="r-gridextra"
DEPS[gtools]="r-gtools"
DEPS[limma]="bioconductor-limma"
DEPS[maSigPro]="bioconductor-masigpro"
DEPS[mapdata]="r-mapdata"
DEPS[maps]="r-maps"
DEPS[metagenomeSeq]="bioconductor-metagenomeseq"
DEPS[optparse]="r-optparse"
DEPS[plyr]="r-plyr"
DEPS[qqman]="r-qqman"
DEPS[qqman]="r-qqman"
DEPS[reshape]="r-reshape"
DEPS[reshape2]="r-reshape2"
DEPS[rtracklayer]="bioconductor-rtracklayer"
DEPS[samr]="r-samr"
DEPS[scales]="r-scales"
DEPS[siggenes]="bioconductor-siggenes"
DEPS[sleuth]="r-sleuth"
DEPS[snow]="r-snow"
DEPS[vegan]="r-vegan"

grep -i 'library(' -r ${REPO_FOLDER}/{CGAT,R} \
 | grep -v Binary \
 | sed -e 's/\(.*\)library\(.*\)/\2/' \
 | sed 's/[()"&,.%'\'']//g' \
 | sed 's/\\n$//g' \
 | egrep '^[a-zA-Z]{2,}' \
 | egrep -v 'spp|zinba' \
 | sort -u \
 >  ${TMP_GREP}

for pkg in `cat ${TMP_GREP}` ;
do

   # Reference:
   # http://www.artificialworlds.net/blog/2012/10/17/bash-associative-array-examples/
   if [[ ${DEPS[${pkg}]+_} ]] ; then
      # found
      [[ "${DEPS[${pkg}]}" != "ignore" ]] && echo "- "${DEPS[${pkg}]} >> ${TMP_DEPS}
   else
      # not found
      echo "- "$pkg >> ${TMP_DEPS}
   fi

done

# r-base always goes first
echo "- r-base"

# Print them all sorted
sort -u ${TMP_DEPS} | grep '\- r'
sort -u ${TMP_DEPS} | grep '\- bioconductor'

# Remove temp files
rm ${TMP_GREP}
rm ${TMP_DEPS}

