#!/usr/bin/env bash

set -e
set -u
#set -x
set -o pipefail

### This script runs the Checker Framework's tests that depend on
### dljc (this project). It is intended to be used as part of a CI integration test.
### This script must be run from the top-level directory
### It performs these actions:
### 1. fetches plume-scripts
### 2. uses git-clone-related to clone either the Checker Framework master version or the current user's
###    fork of the CF on the same branch, if it exists
### 3. re-clones this repo/branch in the clone of the CF at its checker/bin/.do-like-javac directory
### 4. runs the CF tests that use dljc

### get plume-scripts

if [ -d /tmp/"$USER"/plume-scripts ] ; then
  git -C /tmp/"$USER"/plume-scripts pull -q > /dev/null 2>&1
else
  mkdir -p /tmp/"$USER" && git -C /tmp/"$USER" clone --depth 1 -q https://github.com/plume-lib/plume-scripts.git
fi

### clone the CF

/tmp/"$USER"/plume-scripts/git-clone-related typetools checker-framework /tmp/"$USER"/checker-framework

### setup the CF to use this repo/branch of dljc

rm -rf /tmp/"$USER"/checker-framework/checker/bin/.do-like-javac

# I know we already have this---we're in a copy of it right now!---but I want to make sure that
# git is configured correctly so that when the CF scripts run `git pull` in checker/bin/.do-like-javac
# they don't fail.
/tmp/"$USER"/plume-scripts/git-clone-related kelloggm do-like-javac /tmp/"$USER"/checker-framework/checker/bin/.do-like-javac

# don't think I need these
#CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
#CURRENT_ORIGIN=$(git remote get-url origin)

### run the CF tests
cd /tmp/"$USER"/checker-framework
./gradlew wpiManyTests wpiPlumeLibTests
