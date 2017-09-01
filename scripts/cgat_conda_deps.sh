#!/usr/bin/env bash
#
# Script to find Python and R deps in this repository
#
# It uses snakefood to find the python dependencies
#

# exit when a command fails
#set -o errexit

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
TMP_MISC=$(mktemp)
TMP_DEPS=$(mktemp)

# dictionary to translate Python deps
declare -A PY_DEPS
PY_DEPS[Bio]="biopython"
PY_DEPS[MySQLdb]="mysqlclient"
PY_DEPS[SphinxReport]="ignore"
PY_DEPS[alignlib_lite]="alignlib-lite"
PY_DEPS[bs4]="beautifulsoup4"
PY_DEPS[bx]="ignore"
PY_DEPS[configparser]="ignore"
PY_DEPS[drmaa]="python-drmaa"
PY_DEPS[lzo]="python-lzo"
PY_DEPS[metaphlan_utils]="ignore"
PY_DEPS[pyBigWig]="pybigwig"
PY_DEPS[pyximport]="ignore"
PY_DEPS[sklearn]="scikit-learn"
PY_DEPS[web]="web.py"
PY_DEPS[weblogolib]="python-weblogo"
PY_DEPS[yaml]="pyyaml"

# dictionary to translate R deps
declare -A R_DEPS
R_DEPS[BiSeq]="bioconductor-biseq"
R_DEPS[Biobase]="bioconductor-biobase"
R_DEPS[ChIPQC]="bioconductor-chipqc"
R_DEPS[DESeq2]="bioconductor-deseq2"
R_DEPS[DESeq]="bioconductor-deseq"
R_DEPS[DEXSeq]="bioconductor-dexseq"
R_DEPS[GMD]="r-gmd"
R_DEPS[HiddenMarkov]="r-hiddenmarkov"
R_DEPS[HilbertVis]="bioconductor-hilbertvis"
R_DEPS[Hmisc]="r-hmisc"
R_DEPS[IHW]="bioconductor-ihw"
R_DEPS[KEGGdb]="bioconductor-kegg.db"
R_DEPS[MASS]="r-mass"
R_DEPS[MEDIPS]="bioconductor-medips"
R_DEPS[RColorBrewer]="r-rcolorbrewer"
R_DEPS[RSQLite]="r-rsqlite"
R_DEPS[VennDiagram]="r-venndiagram"
R_DEPS[WGCNA]="r-wgcna"
R_DEPS[affy]="bioconductor-affy"
R_DEPS[amap]="r-amap"
R_DEPS[biomaRt]="bioconductor-biomart"
R_DEPS[coloc]="r-coloc"
R_DEPS[cummeRbund]="bioconductor-cummerbund"
R_DEPS[database]="ignore"
R_DEPS[dplyr]="r-dplyr"
R_DEPS[edgeR]="bioconductor-edger"
R_DEPS[flashClust]="r-flashclust"
R_DEPS[gcrma]="bioconductor-gcrma"
R_DEPS[genome_file]="ignore"
R_DEPS[ggplot2]="r-ggplot2"
R_DEPS[gplots]="r-gplots"
R_DEPS[gridExtra]="r-gridextra"
R_DEPS[grid]="r-gridbase"
R_DEPS[gtools]="r-gtools"
R_DEPS[hpar]="bioconductor-hpar"
R_DEPS[limma]="bioconductor-limma"
R_DEPS[maSigPro]="bioconductor-masigpro"
R_DEPS[mapdata]="r-mapdata"
R_DEPS[maps]="r-maps"
R_DEPS[metagenomeSeq]="bioconductor-metagenomeseq"
R_DEPS[optparse]="r-optparse"
R_DEPS[plotrix]="r-plotrix"
R_DEPS[plyr]="r-plyr"
R_DEPS[pvclust]="r-pvclust"
R_DEPS[qqman]="r-qqman"
R_DEPS[reshape2]="r-reshape2"
R_DEPS[reshape]="r-reshape"
R_DEPS[rtracklayer]="bioconductor-rtracklayer"
R_DEPS[samr]="r-samr"
R_DEPS[scales]="r-scales"
R_DEPS[sciplot]="r-sciplot"
R_DEPS[siggenes]="bioconductor-siggenes"
R_DEPS[simpleaffy]="bioconductor-simpleaffy"
R_DEPS[sleuth]="r-sleuth"
R_DEPS[snow]="r-snow"
R_DEPS[spp]="ignore"
R_DEPS[vegan]="r-vegan"
R_DEPS[wasabi]="r-wasabi"
R_DEPS[zinba]="ignore"


# dictionary to translate R deps
declare -A MISC_DEPS
MISC_DEPS[gat-run.py]="gat"
MISC_DEPS[intersectBed]="bedtools"
MISC_DEPS[samtools]="samtools"

# function to report issues and exit
report_problem() {
   echo
   echo $1
   echo
   echo " Aborting. "
   exit 1
}


# function to find python imports
# output will go to TMP_SFOOD
find_python_imports() {

sfood $1 2>&1 \
 | grep 'WARNING     :   ' \
 | grep -v Line \
 | awk '{print $3;}' \
 | grep -v '^_.*' \
 | sed 's/\..*//g' \
 | egrep -v 'CGAT|XGram|builtins|corebio|pylab|xml' \
 | sort -u \
 >> ${TMP_SFOOD}

}


# function to find R imports
# output will go to TMP_GREP
find_r_imports() {

grep -i 'library(' -r $1 \
 | grep -v Binary \
 | sed -e 's/\(.*\)library\(.*\)/\2/' \
 | sed 's/[()"&,.%'\'']//g' \
 | sed 's/\\n$//g' \
 | egrep '^[a-zA-Z]{2,}' \
 | sort -u \
 >> ${TMP_GREP}

}


# function to find misc programs
# output will go to TMP_MISC
find_misc_programs() {

   # Not sure why, but this is required to run properly
   FIND_DIR=$1

   # will use specific py3 env
   source deactivate
   source /ifs/apps/conda-envs/bin/activate py3-basic

   TMP_EXT=$(mktemp)
   find ${FIND_DIR} -iname "*.py" \
        > ${TMP_EXT}

   for code in `cat ${TMP_EXT}` ;
   do

      python ${REPO_FOLDER}/scripts/cgat_check_deps.py ${code} \
       | egrep -v 'PATH|^$|^cgat$|^No|^R|^Rscript|^cd' \
       >> ${TMP_MISC}

   done

   # return unique names
   cat ${TMP_MISC} | sort -u > ${TMP_EXT}
   cp ${TMP_EXT} ${TMP_MISC}

   # revert to original env
   source deactivate
   source /ifs/apps/conda-envs/bin/activate snakefood

   # clean up tmp file
   rm ${TMP_EXT}

}


# function to display help message
help_message() {
   echo
   echo " Scans this repository to look for conda dependencies."
   echo
   echo " To get the dependencies for all scripts, run:"
   echo " ./cgat_conda_deps.sh --all"
   echo
   echo " To get the dependencies for production scripts only, run:"
   echo " ./cgat_conda_deps.sh --production"
   echo
   exit 1
}


# the script starts here

if [[ $# -eq 0 ]] ; then

   help_message

fi

# variable to choose scope
ALL=1
# variable to store input parameters
INPUT_ARGS=$(getopt -n "$0" -o hap --long "help,
                                           all,
                                           production"  -- "$@")
eval set -- "$INPUT_ARGS"

# process all the input parameters first
while [[ "$1" != "--" ]]
do

   if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] ; then

      help_message

   elif [[ "$1" == "--all" ]] ; then

      ALL=1
      shift ;

   elif [[ "$1" == "--production" ]] ; then

      ALL=0
      shift ;

   else

      help_message

   fi

done

# requirement: snakefood
source /ifs/apps/conda-envs/bin/activate snakefood

# initialize temp files
cat /dev/null > ${TMP_SFOOD}
cat /dev/null > ${TMP_GREP}
cat /dev/null > ${TMP_MISC}
cat /dev/null > ${TMP_DEPS}

# find deps depending on given input
if [[ ${ALL} -eq 1 ]] ; then

   # Python
   find_python_imports "${REPO_FOLDER}/CGAT"

   # R
   find_r_imports "${REPO_FOLDER}/CGAT"
   find_r_imports "${REPO_FOLDER}/R"

   # Misc
   find_misc_programs "${REPO_FOLDER}/CGAT"

else
   # Use tmp folder
   TMP_D=$(mktemp -d)/cgat
   mkdir -p ${TMP_D}

   # Bring production scripts to tmp folder
   grep CGAT ${REPO_FOLDER}/MANIFEST.in \
    | egrep -v '#|install|exclude|h$|c$|cpp$|pxd$|pyx' \
    | awk '{print $2;}' \
    > ${TMP_D}/grep-patterns

   for f in `find ${REPO_FOLDER}/CGAT | grep -f ${TMP_D}/grep-patterns` ; do cp $f ${TMP_D}/ ; done
   find ${REPO_FOLDER}/CGAT/scripts/ -regex '.*pyx.*' -exec cp {} ${TMP_D}/ \;

   # Python
   find_python_imports "${TMP_D}"

   # R
   find_r_imports "${TMP_D}"

   # Misc
   find_misc_programs "${TMP_D}"

   echo "###"
   for f in `ls ${TMP_D}` ; do echo "${TMP_D}/${f}" ; grep statement ${TMP_D}/${f} ; done
   echo "###"

   # clean up
   [[ -n "${TMP_D}" ]] && rm -rf "${TMP_D}"

fi

### process python deps ###

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

# print Python section
echo "# python dependencies"
echo "- python"

# Add others manually:
echo "- cython" >> ${TMP_DEPS}
echo "- nose" >> ${TMP_DEPS}
echo "- pep8" >> ${TMP_DEPS}
echo "- setuptools" >> ${TMP_DEPS}

# Print them all sorted
sort -u ${TMP_DEPS}

# Add bx-python from PyPI at the end
echo "- pip:"
echo "  - bx-python"


### process R deps ###

cat /dev/null > ${TMP_DEPS}

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

# print R section
R_DEPS_SIZE=$(stat --printf="%s" ${TMP_DEPS})
[[ ${R_DEPS_SIZE} -gt 0 ]] && \
echo "# R dependencies" && \
echo "- r-base" && \
sort -u ${TMP_DEPS} | grep '\- r'
[[ ${R_DEPS_SIZE} -gt 0 ]] && \
sort -u ${TMP_DEPS} | grep '\- bioconductor'


### process misc programs ###

cat /dev/null > ${TMP_DEPS}

for pkg in `cat ${TMP_MISC}` ;
do

   # Reference:
   # http://www.artificialworlds.net/blog/2012/10/17/bash-associative-array-examples/
   if [[ ${MISC_DEPS[${pkg}]+_} ]] ; then
      # found
      [[ "${MISC_DEPS[${pkg}]}" != "ignore" ]] && echo "- "${MISC_DEPS[${pkg}]} >> ${TMP_DEPS}
   else
      # not found
      echo "? "$pkg >> ${TMP_DEPS}
   fi

done

# print misc section
MISC_DEPS_SIZE=$(stat --printf="%s" ${TMP_DEPS})
[[ ${MISC_DEPS_SIZE} -gt 0 ]] && \
echo "# Misc dependencies" && \
sort -u ${TMP_DEPS}


# Remove temp files
rm ${TMP_SFOOD}
rm ${TMP_GREP}
rm ${TMP_MISC}
rm ${TMP_DEPS}

