#!/bin/sh

# A wrapper around the `mvn` command line tool which adds support for a single
# additional flag, namely '-O'. When provided, Maven will build only modules
# affected by uncommitted changes in the current working directory. The code is
# assumed to be versioned using Git.

# If one configures this script as an alias for `mvn`, then the -O flag will be
# supported transparently, retaining the command auto-completion support the
# shell may provide.

set -e

# Replacement for GNU xargs -r
maybe_xargs() {
  _in=
  while read _line; do
    if [ -z "${_line}" ]; then
      continue
    fi
    _in="${_line} ${_in}"
  done
  if [ -n "${_in}" ]; then
    "$@" ${_in}
  fi
}

find_module() {
  NDIR=$(dirname "$1")
  DIR="."
  while [ ! "$NDIR" = "$DIR" ] && [ ! -f "$NDIR/pom.xml" ]; do
    DIR="$NDIR"
    NDIR=$(dirname "$DIR")
  done
  echo "$NDIR"
}

real_args=
optimize=
while [ $# -gt 0 ]; do
  if [ "$1" = "-O" ]; then
    optimize=true
  else
    real_args="${real_args} \"$1\""
  fi
  shift
done

if [ -z "${optimize}" ]; then
  # Regular Maven execution requested. Pass on all arguments as-is.
  eval mvn ${real_args}
else
  # Optimized Maven execution requested. Drop the custom flag.
  set -- ${real_args}

  if ! git rev-parse --is-inside-git-dir > /dev/null 2>&1; then
    # This is not a Git repository; can't optimize the build.
    mvn "$@"
  else
    # All is well. Perform the optimized Maven execution.
    #
    # For each modified file, print the root directory of the innermost Maven #
    # module to which the file belongs. Remove duplicates and join the
    # remaining module directory names with commas. Lastly, instruct Maven to
    # only build modified modules and their dependents.
    git ls-files --modified | while read _file; do
      find_module "${_file}"
    done \
      | sort -u \
      | xargs echo \
      | tr ' ' ',' \
      | maybe_xargs mvn "$@" -amd -pl
  fi
fi
