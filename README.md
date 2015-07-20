# Maven build wrapper for Git-versioned multi-module builds

The `git-mvn-wrapper.sh` script is a wrapper around the Maven CLI. It adds
support for the `-O` flag, using which one instructs Maven to build only those
modules in a multi-module build that are affected by uncommitted changes, as
indicated by Git.

### Installation

1. Download [`git-mvn-wrapper.sh`](git-mvn-wrapper.sh) and store it at
   `/some/convenient/path/git-mvn-wrapper.sh`.
2. Add the following alias definition to your shell's configuration (and
   `source` it again, or open a new shell):

    ```
    alias mvn=/some/convenient/path/git-mvn-wrapper.sh
    ```
    
### Usage

You can now invoke the `mvn` command as before, and optionally provide the `-O`
flag to attempt an optimized build. I.e.,

```
$ mvn clean install       # Will perform a full build as usual.
$ mvn -O clean install    # Will only build modified modules;
                          # may terminate immediately if there are no changes.
```
