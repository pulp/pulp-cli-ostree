# Changelog

[//]: # (You should *NOT* be adding new change log entries to this file, this)
[//]: # (file is managed by towncrier. You *may* edit previous change logs to)
[//]: # (fix problems like typo corrections or such.)
[//]: # (To add a new change log entry, please see)
[//]: # (https://docs.pulpproject.org/contributing/git.html#changelog-update)

[//]: # (WARNING: Don't drop the towncrier directive!)

[//]: # (towncrier release notes start)

## 0.2.0 (2023-11-16)
=====================


### Misc

- [#59](https://github.com/pulp/pulp-cli-ostree/issues/59)


---## 0.1.1 (2023-05-15)
=====================


No significant changes.


---


## 0.1.0 (2023-04-03)
=====================


### Features

- Ported pulp-cli-ostree to pulp-glue.
  [#38](https://github.com/pulp/pulp-cli-ostree/issues/38)


---


## 0.0.3 (2022-06-24)

### Features

- Added support for specifying a list of refs that should be filtered out from a remote repository.
  [#16](https://github.com/pulp/pulp-cli-ostree/issues/16)
- Decoupled workflows for importing all refs and commits. To import everything from a tarball, one
  should use the ``import-all`` command. When importing commits assigned to a specific ref, it is
  recommended to use the ``import-commits`` command.
  [#19](https://github.com/pulp/pulp-cli-ostree/issues/19)


---


## 0.0.2 (2022-02-12)

### Features

- Added support for adding and removing config files across repositories.
  [#14](https://github.com/pulp/pulp-cli-ostree/issues/14)


---


## 0.0.1 (2022-01-12)

### Features

- Added the CLI for basic workflows (i.e., managing, syncing, importing repositories).
  [#5](https://github.com/pulp/pulp-cli-ostree/issues/5)


---
