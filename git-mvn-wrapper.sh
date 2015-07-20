#!/bin/sh

# A wrapper around the `mvn` command line tool which adds support for a single
# additional flag, namely '-O'. When provided, Maven will build only modules
# affected by uncommitted changes in the current working directory. The code is
# assumed to be versioned using Git.

# If one configures this script as an alias for `mvn`, then the -O flag will be
# supported transparently, retaining the command auto-completion support the
# shell may provide.

set -e

if ! echo "$*" | grep -qE '(^|\s)-O(\s|$)'; then
  # Regular Maven execution requested. Pass on all arguments as-is.
  mvn "$@"
else
  # Optimized Maven execution requested. Drop the custom flag.
  ARGS=$(echo "$*" | sed -r 's,(^|\s)-O(\s|$),\1\2,')
  set -- $ARGS

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
    git ls-files --modified \
      | xargs -I{} sh -c '
          NDIR=$(dirname "{}")
          DIR="."
          while [ ! "$NDIR" = "$DIR" ] && [ ! -f "$NDIR/pom.xml" ]; do
            DIR="$NDIR"
            NDIR=$(dirname "$DIR")
          done
          echo "$NDIR"
      ' \
      | sort -u \
      | sed -z 's/\n/,/g' \
      | xargs -r mvn $@ -amd -pl
  fi
fi
