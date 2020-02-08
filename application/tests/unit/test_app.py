# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import unittest

import os,sys,inspect
unitdir = os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))
testsdir = os.path.dirname(currentdir)
applicationdir = os.path.dirname(testsdir)
sys.path.insert(0,applicationdir)

from app import hello_world

class TestHelloApp(unittest.TestCase):

  def test_hello(self):
    target = os.environ.get('COMPANY', 'Leonteq')
    self.assertEqual(hello_world(), "Hello {0} from Gustavo Benitez\n".format(target))

if __name__ == '__main__':
  unittest.main()
