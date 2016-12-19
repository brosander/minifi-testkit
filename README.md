This is a repository aimed at testing the minifi command line toolkit.  It automates configuration and running of a minifi docker container with a given configuration.

NOTE: This testkit spins up 2 nifi containers, 2 squid containers, and a postgres container for use by the test flows.  This is in addition to the minifi containers that are run 1 at a time.  I suggest 8 gb of ram at minimum (I also run with 4 cpus) allocated to the docker vm.

Usage:

```
./setup.sh MINIFI_REPO_DIR NIFI_ARCHIVE
cd target/
./startup.sh
./run-all.sh
```
