'''
cgat_check_deps.py - check whether the software dependencies are on your PATH
=============================================================================

Purpose
-------

.. The goal of this script is to provide a list of third-party command-line
programs used in a Python script given as input, and check whether
they are on your PATH. This is useful to identify dependencies across all
CGAT pipelines and module files.

This script takes the path to a Python script, which is expected to call
command-line programs like we do in CGAT pipelines, i.e.:

   statement = """cmd-1 | cmd-2 | cmd-3""""
   P.run()

Programs called other way (e.g. using subprocess) will not be picked up
by this script.

Usage
-----

.. python cgat_check_deps --pipeline </path/to/pipeline_name.py> [--print-summary]

Example::

   python cgat_check_deps --pipeline CGATPipelines/pipeline_annotations.py

Type::

   cgat cgat_check_deps --help

for command line help.

Command line options
--------------------

'''

import os
import shutil
import sys
import re
import ast
import argparse
import subprocess


def checkDepedencies(pipeline):

    # check existence of pipeline script
    if not os.access(pipeline, os.R_OK):
        raise IOError("Pipeline %s was not found\n" % pipeline)

    if os.path.isdir(pipeline):
        raise IOError("The given input is a folder, and must be a script\n")

    # parse pipeline script
    with open(pipeline) as f:
        tree = ast.parse(f.read())

    # list to store all statements = ''' <commands> '''
    statements = []

    # inspired by
    # https://docs.python.org/3/library/ast.html#module-ast
    # http://bit.ly/2rDf5xu
    # http://bit.ly/2r0Uv9t
    # really helpful, used astviewer (installed in a conda-env) to inspect examples
    # https://github.com/titusjan/astviewer
    for node in ast.walk(tree):
        if type(node) is ast.Assign and \
           hasattr(node, 'targets') and \
           hasattr(node.targets[0], 'id') and \
           node.targets[0].id == "statement":

            statement = ""
            if hasattr(node.value, 's'):
                statement = node.value.s
            elif hasattr(node.value, 'left') and hasattr(node.value.left, 's'):
                statement = node.value.left.s

            if len(statement) > 0:
                # clean up statement, code copied from Execution module of Pipeline.py
                statement = " ".join(re.sub("\t+", " ", statement).split("\n")).strip()
                if statement.endswith(";"):
                    statement = statement[:-1]
                statements.append(statement)

    # dictionary where:
    # key = program name
    # value = number of times it has been called
    deps = {}

    # set of names that are not proper deps
    exceptions = ['create',
                  'drop',
                  'select',
                  'attach',
                  'insert',
                  'module',
                  'checkpoint',
                  'for']

    for statement in statements:
        for command in statement.split("|"):
            # take program name, thanks http://pythex.org/
            groups = re.match("^\s*([\w|\-|\.]+)", command)
            if groups is not None:
                # program name is first match
                prog_name = groups.group(0)
                # clean up duplicated white spaces
                prog_name = ' '.join(prog_name.split())
                # filter exceptions
                if prog_name.lower() not in exceptions:
                    if prog_name not in deps:
                        deps[prog_name] = 1
                    else:
                        deps[prog_name] += 1

    # list of unmet dependencies
    check_path_failures = []

    # print dictionary ordered by value
    for k in sorted(deps, key=deps.get, reverse=True):
        if shutil.which(k) is None:
            check_path_failures.append(k)

    return deps, check_path_failures


def main(argv=None):
    """script main.
    parses command line options in sys.argv, unless *argv* is given.
    """

    if (sys.version_info < (3, 0, 0)):
        raise OSError("This script is Python 3 only")
        sys.exit(-1)

    if argv is None:
        argv = sys.argv

    # setup command line parser
    parser = argparse.ArgumentParser(description='Get 3rd party dependencies.')

    parser.add_argument("pipeline", help="Path to CGAT pipeline or module")

    parser.add_argument("-s", "--print-summary", dest="summary",
                        action="store_true", default=False,
                        help="Print how many times a program is used")

    options = parser.parse_args()

    # get dependencies dependencies
    deps, check_path_failures = checkDepedencies(options.pipeline)

    # print info about dependencies
    if len(deps) == 0:
        print('\nNo dependencies found.\n')
    else:
        # print dictionary ordered by value
        if options.summary:
            for k in sorted(deps, key=deps.get, reverse=True):
                print('\nProgram: {0!s} used {1} time(s)'.format(k, deps[k]))

        n_failures = len(check_path_failures)
        if n_failures == 0:
            print('\nCongratulations! All required programs are available on your PATH\n')
        else:
            print('\nThe following programs are not on your PATH')
            for p in check_path_failures:
                print('\n{0!s}'.format(p))
            print


if __name__ == "__main__":
    sys.exit(main(sys.argv))
