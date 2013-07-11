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

export LC_ALL=C

BASEDIR=$(cd $(dirname $0); pwd)

mkdir -p $BASEDIR/done

while true; do
    for f in $(ls -rt $BASEDIR/queue); do
	if ! ssh-add -l > /dev/null; then
	    exit 1
	fi
        mv $BASEDIR/queue/$f $BASEDIR/done
        project=$(cat $BASEDIR/done/$f)

	echo "$f $project"

	projectname=$(basename $project)

	if [ -d $HOME/git/$projectname ]; then
	    GITDIR=$HOME/git/$projectname
	    id=${f/.*/}
	    number=${f/*./}
	    $BASEDIR/verify-patch.sh $id $number $GITDIR $BASEDIR/log 2>&1 | tee -a $BASEDIR/log/$f.log.txt
	fi
        echo "=================================================="
    done
    sleep 30
    python create-work.py < stream
done

# do-work.sh ends here
