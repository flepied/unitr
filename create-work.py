#!/usr/bin/env python
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

import json
import os
import sys

QUEUE='/home/fred/work/unitr/queue'
WORK='/home/fred/work/unitr/work'

if __name__ == "__main__":
    while True:
        try:
            entry = json.loads(sys.stdin.readline())
        except ValueError:
            break
        if entry['type'] == 'patchset-created':
            data = entry['change']
            filename = data['number'] + '.' + entry['patchSet']['number']
            queue_name = QUEUE + '/' + filename
            work_name = WORK +  '/' + filename
            if not (os.path.exists(queue_name) or os.path.exists(work_name)):
                print filename, data['project']
                open(queue_name, 'w').write(data['project'])

# create-work.py ends here
