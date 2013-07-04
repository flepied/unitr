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
    echo "https://review.openstack.org/#/c/$review/"
    exit 1
}

set -e

if [ $# != 3 ]; then
    echo "Usage: $0 <review id> <git basedir> <log dir>" 1>&2
    exit 1
fi

if ! type -p filterdiff > /dev/null 2>&1; then
    echo "Install filterdiff" 1>&2
    exit 1
fi

review="$1"
BASEDIR="$2"
LOGDIR="$3"

cd $BASEDIR

git checkout .
git clean -d -f > /dev/null

git review -d "$review"
rev=$(git rev-parse HEAD)
branch=$(git rev-parse --abbrev-ref HEAD)

echo "Processing $rev pointed by $branch"

git checkout master
git branch -D $branch
git show $rev  > diff.$$
filterdiff -i '*/test*' < diff.$$ > fdiff.$$

# No test
if [ ! -s fdiff.$$ ]; then
    echo "No test"
    if [ -z "$(sed -n -e 's/^+++ //p' < diff.$$ | egrep -v '/doc/|.*\.pot?')" ]; then
	success "Only doc"
    else
	failure "Code without test -> not good."
    fi
fi

# Only tests so no need to work further 
if [ -z "$(sed -n -e 's/^+++ //p' < diff.$$ | egrep -v '.*/test.*\.py')" ]; then
    success "Only tests, nothing to check"
fi

# Apply the filtered diff with only tests
patch -p1 < fdiff.$$

# We have code so see if at least one test fails without the code
echo "+ Running ./run_tests.sh"
if ! ./run_tests.sh >> $LOGDIR/$review.tests 2>&1; then
    success "Some tests are failing before applying the new code"
else
    failure "No test is failing (before adding the code) -> not good"
fi

# verify-patch.sh ends here
