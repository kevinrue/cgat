#!/usr/bin/env bash
#
# Script to find Python and R deps in this repository
#
# It uses snakefood to find the python dependencies
#

# exit when a command fails
set -o errexit

# exit if any pipe commands fail
set -o pipefail

# exit when your script tries to use undeclared variables
#set -o nounset

# trace what gets executed
#set -o xtrace

SCRIPT_FOLDER=$(dirname $0)
REPO_FOLDER=$(dirname ${SCRIPT_FOLDER})
TMP_SFOOD=$(mktemp)
TMP_GREP=$(mktemp)
TMP_DEPS=$(mktemp)

# dictionary to translate Python deps
declare -A PY_DEPS
PY_DEPS[Bio]="biopython"
PY_DEPS[MySQLdb]="mysqlclient"
PY_DEPS[alignlib_lite]="alignlib-lite"
PY_DEPS[bx]="ignore"
PY_DEPS[configparser]="ignore"
PY_DEPS[lzo]="python-lzo"
PY_DEPS[pyximport]="ignore"
PY_DEPS[sklearn]="scikit-learn"
PY_DEPS[weblogolib]="python-weblogo"
PY_DEPS[yaml]="pyyaml"

declare -A R_DEPS
R_DEPS[Biobase]="bioconductor-biobase"
R_DEPS[DESeq2]="bioconductor-deseq2"
R_DEPS[DESeq]="bioconductor-deseq"
R_DEPS[DEXSeq]="bioconductor-dexseq"
R_DEPS[HilbertVis]="bioconductor-hilbertvis"
R_DEPS[IHW]="bioconductor-ihw"
R_DEPS[MEDIPS]="bioconductor-medips"
R_DEPS[RColorBrewer]="r-rcolorbrewer"
R_DEPS[VennDiagram]="r-venndiagram"
R_DEPS[WGCNA]="r-wgcna"
R_DEPS[biomaRt]="bioconductor-biomart"
R_DEPS[coloc]="r-coloc"
R_DEPS[database]="ignore"
R_DEPS[edgeR]="bioconductor-edger"
R_DEPS[flashClust]="r-flashclust"
R_DEPS[genome_file]="ignore"
R_DEPS[ggplot2]="r-ggplot2"
R_DEPS[gplots]="r-gplots"
R_DEPS[gridExtra]="r-gridextra"
R_DEPS[grid]="r-gridbase"
R_DEPS[gtools]="r-gtools"
R_DEPS[limma]="bioconductor-limma"
R_DEPS[maSigPro]="bioconductor-masigpro"
R_DEPS[mapdata]="r-mapdata"
R_DEPS[maps]="r-maps"
R_DEPS[metagenomeSeq]="bioconductor-metagenomeseq"
R_DEPS[optparse]="r-optparse"
R_DEPS[plyr]="r-plyr"
R_DEPS[qqman]="r-qqman"
R_DEPS[reshape2]="r-reshape2"
R_DEPS[reshape]="r-reshape"
R_DEPS[rtracklayer]="bioconductor-rtracklayer"
R_DEPS[samr]="r-samr"
R_DEPS[scales]="r-scales"
R_DEPS[siggenes]="bioconductor-siggenes"
R_DEPS[sleuth]="r-sleuth"
R_DEPS[snow]="r-snow"
R_DEPS[vegan]="r-vegan"

# requirement: snakefood
source /ifs/apps/conda-envs/bin/activate snakefood

## create python section

sfood ${REPO_FOLDER}/CGAT 2>&1 \
 | grep 'WARNING     :   ' \
 | grep -v Line \
 | awk '{print $3;}' \
 | grep -v '^_.*' \
 | sed 's/\..*//g' \
 | egrep -v 'CGAT|XGram|builtins|corebio|pylab|xml' \
 | sort -u \
 > ${TMP_SFOOD}

for pkg in `cat ${TMP_SFOOD}` ;
do

   # Reference:
   # http://www.artificialworlds.net/blog/2012/10/17/bash-associative-array-examples/
   if [[ ${PY_DEPS[${pkg}]+_} ]] ; then
      # found
      [[ "${PY_DEPS[${pkg}]}" != "ignore" ]] && echo "- "${PY_DEPS[${pkg}]} >> ${TMP_DEPS}
   else
      # not found
      echo "- "$pkg >> ${TMP_DEPS}
   fi

done

# Add others manually:
echo "- cython" >> ${TMP_DEPS}
echo "- nose" >> ${TMP_DEPS}
echo "- pep8" >> ${TMP_DEPS}
echo "- setuptools" >> ${TMP_DEPS}

# Python always goes first
echo "# python dependencies"
echo "- python"

# Print them all sorted
sort -u ${TMP_DEPS}

# Add bx-python from PyPI at the end
echo "- pip:"
echo "  - bx-python"

## create R section
cat /dev/null > ${TMP_DEPS}

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
   if [[ ${R_DEPS[${pkg}]+_} ]] ; then
      # found
      [[ "${R_DEPS[${pkg}]}" != "ignore" ]] && echo "- "${R_DEPS[${pkg}]} >> ${TMP_DEPS}
   else
      # not found
      echo "- "$pkg >> ${TMP_DEPS}
   fi

done

# r-base always goes first
echo "# R dependencies"
echo "- r-base"

# Print them all sorted
sort -u ${TMP_DEPS} | grep '\- r'
sort -u ${TMP_DEPS} | grep '\- bioconductor'

# Remove temp files
rm ${TMP_SFOOD}
rm ${TMP_GREP}
rm ${TMP_DEPS}

