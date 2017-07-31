#!/usr/bin/env bash
#
# Script to find Python deps in this repository
#
# It uses snakefood to find the python dependencies
#

SCRIPT_FOLDER=$(dirname $0)
REPO_FOLDER=$(dirname ${SCRIPT_FOLDER})
TMP_SFOOD=$(mktemp)
TMP_DEPS=$(mktemp)

declare -A DEPS
DEPS[Bio]="biopython"
DEPS[MySQLdb]="mysqlclient"
DEPS[alignlib_lite]="alignlib-lite"
DEPS[bx]="ignore"
DEPS[configparser]="ignore"
DEPS[lzo]="python-lzo"
DEPS[pyximport]="ignore"
DEPS[sklearn]="scikit-learn"
DEPS[weblogolib]="python-weblogo"
DEPS[yaml]="pyyaml"

# requirement: snakefood
source /ifs/apps/conda-envs/bin/activate snakefood

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
   if [[ ${DEPS[${pkg}]+_} ]] ; then
      # found
      [[ "${DEPS[${pkg}]}" != "ignore" ]] && echo "- "${DEPS[${pkg}]} >> ${TMP_DEPS}
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
echo "- python"

# Print them all sorted
sort -u ${TMP_DEPS}

# Add bx-python from PyPI at the end
echo "- pip:"
echo "  - bx-python"

# Remove temp files
rm ${TMP_SFOOD}
rm ${TMP_DEPS}

