unitr
=====

``verify-patch.sh`` is a tool to verify a proposed commit to gerrit by
extracting the commit using ``git-review`` and then filtering to apply
only the unit tests to the project and verify that they fail.

It tries to cope with the following cases to avoid false positives:

* Only documentation commit.
* Only tests commit aka unit test fixes or unit tests refactoring.

On the other hand, it will report an error if the commit comes with
code but without unit tests.

This has been designed to help reviewers on the OpenStack project.
