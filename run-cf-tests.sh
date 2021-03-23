#!/usr/bin/env bash

set -e
set -u
set -x
set -o pipefail

### This script runs the Checker Framework's tests that depend on
### dljc (i.e. this project's main script). It is intended to be used as part of a CI integration test.
### This script must be run from the top-level directory

### get plume-scripts so that we can use git-clone-related

if [ -d /tmp/"$USER"/plume-scripts ] ; then
  git -C /tmp/"$USER"/plume-scripts pull -q > /dev/null 2>&1
else
  mkdir -p /tmp/"$USER" && git -C /tmp/"$USER" clone --depth 1 -q https://github.com/plume-lib/plume-scripts.git
fi

### clone the CF. If there is a branch with the same name as this branch, git-clone-related will check out that branch.
### To facilitate that during CI runs, switch to the branch with the BASE_BRANCH variable's value if it's available.
### This variable is set by the wpiMany.yml script when running in CI.
rm -rf /tmp/"$USER"/checker-framework
if [ -n "${BASE_BRANCH+x}" ]; then
  CURR_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  git checkout "${BASE_BRANCH}"
fi
/tmp/"$USER"/plume-scripts/git-clone-related typetools checker-framework /tmp/"$USER"/checker-framework
export CHECKERFRAMEWORK=/tmp/"$USER"/checker-framework
if [ -n "${CURR_BRANCH+x}" ]; then
  git checkout "${CURR_BRANCH}"
fi

### enforce that the copy of DLJC being used by the CF is identical to this one by copying
### the contents of this repo to checker/bin/.do-like-javac. It is not sufficient to rely on
### git-clone-related in the CF's tests for this, because the name of the branch in the current
### might or might not correspond to something that's actually checked in. For example, GitHub
### Actions pull_request builds always use the branch name "merge" for the build, because they
### merge the PR branch into master before running. git-clone-related in the CF will end up
### pulling from DLJC's master when executing the tests, but that *should* be okay.
rm -rf "${CHECKERFRAMEWORK}"/checker/bin/.do-like-javac
mkdir -p "${CHECKERFRAMEWORK}"/checker/bin/.do-like-javac
cp -r * "${CHECKERFRAMEWORK}"/checker/bin/.do-like-javac/

### run the CF tests
cd "${CHECKERFRAMEWORK}"
./gradlew wpiManyTests wpiPlumeLibTests
