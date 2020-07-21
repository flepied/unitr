#!/bin/bash
#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Frederic Lepied <frederic.lepied@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

success() {
    echo "Success: $*"
    exit 0
}

failure() {
    echo "Failure: $*"
    if [ $gerrit -eq 1 ]; then
        echo "https://review.openstack.org/#/c/$review/"
    fi
    exit 1
}

cleanup() {
    git checkout .
    git clean -d -f > /dev/null
    if [ $gerrit -eq 1 ]; then
        git branch -D $branch
    fi
}

set -e

case $# in
    4)
        gerrit=1
        ;;
    3)
        gerrit=0
        ;;
    *)
        echo "Usage: $0 <review id> <review number> <git basedir> <log dir>" 1>&2
        echo "Usage: $0 <branch name> <git basedir> <log dir>" 1>&2
        exit 1
        ;;
esac

if ! type -p filterdiff > /dev/null 2>&1; then
    echo "Install filterdiff" 1>&2
    exit 1
fi

if [ $gerrit -eq 1 ]; then
    review="$1"
    number="$2"
    BASEDIR="$3"
    LOGDIR="$4"
    log=$LOGDIR/$review.$number.tests.txt
else
    branch="$1"
    BASEDIR="$2"
    LOGDIR="$3"
    log=$LOGDIR/$(echo $branch|sed 's@/@_@g').tests.txt
fi

cd $BASEDIR

if [ $gerrit -eq 1 ]; then
    git review -d "$review,$number"
    rev=$(git rev-parse HEAD)
    branch=$(git rev-parse --abbrev-ref HEAD)

    echo "Processing $rev pointed by $branch"

    git checkout HEAD^ > /dev/null 2>&1
    git show $rev  > diff.$$
else
    git fetch
    git checkout $branch
    git diff -r master > diff.$$
    git checkout master
    git pull
fi

filterdiff -i '*/test*' < diff.$$ > fdiff.$$
trap cleanup 0

# No test
if [ ! -s fdiff.$$ ]; then
    echo "No test"
    if [ -z "$(sed -n -e 's/^+++ //p' < diff.$$ | egrep -v '/doc/|.*\.pot?$|.*\.(rst|txt|md)$')" ]; then
	success "Only doc"
    else
	failure "Code without test -> not good."
    fi
fi

# Only tests so no need to work further 
if [ -z "$(sed -n -e 's/^+++ //p' < diff.$$ | egrep -v '.*/test.*\.py')" ]; then
    success "Only tests, nothing to check"
fi

# find the right python env
if grep -q py37 tox.ini; then
    runner="tox -epy37"
else
    runner="tox -epy27"
fi

# Apply the filtered diff with only tests
if [ $gerrit -eq 1 ]; then
    patch -p1 < fdiff.$$
else
    patch -p0 < fdiff.$$
fi

# We have code so see if at least one test fails without the code
fail=0

for tfile in $(sed -n -e 's@^+++ \([ab]/\)\?@@p' < fdiff.$$ | egrep '.*/test.*\.py'); do
    testname=$(echo "$tfile" | sed -e 's@.*/tests/@@' -e 's@.py@@' -e 's@/@.@g')
    echo "+ Running $runner $testname"
    echo "+ Running $runner $testname" >> $log
    if ! $runner $testname >> $log 2>&1 < /dev/null; then
	fail=1
	break
    fi
done

if [ $fail = 0 ]; then
    failure "No test is failing (before adding the code) -> not good"
else
    success "Some tests are failing before applying the new code"
fi

# verify-patch.sh ends here
