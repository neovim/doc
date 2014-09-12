Marvim Bot CI
=============

[![Build Status](https://travis-ci.org/neovim/bot-ci.svg?branch=master)](https://travis-ci.org/neovim/bot-ci)

This is the part of Marvim's planet sized brain that runs on TravisCI.
However, you won't find the "Genuine People Personalities" technology here.

Generated Content
=================

```
neovim.org
  doc
    dev
    user [todo]
    reports
      clang
      translations
      vimpatch
```

Building Locally
================

To build locally, execute `./ci/<build script>`, where `build script` is any executable shell script. Override environment variables as necessary. For example, to rebuild 64-bit dependencies and push to a `neovim/deps` fork, execute the following:

```bash
NEOVIM_REPO=<username>/neovim \
NEOVIM_BRANCH=my-neovim-branch \
DEPS_REPO=<username>/neovim-deps \
DEPS_BRANCH=my-deps-branch \
./ci/rebuild-deps64.sh
```

Testing PRs
===========

Building of PRs is disabled for this repository, because that would change the contents of `neovim/doc`. To test your PRs using Travis CI, follow these steps:

 * Fork the `neovim/doc` repository to `<username>/doc`.
 * Using your `neovim/bot-ci` fork:
   * Enable Travis CI.
   * Create a new testing branch based on your PR branch (e.g. `git checkout pr-branch && git checkout -b pr-branch-test`).
   * Obtain a [Github personal access token](https://github.com/settings/applications) and encrypt it for Travis using `travis encrypt 'GH_TOKEN=<token>' -r <username>/bot-ci`.
   * Modify `.travis.yml` and override environment variables as necessary, e.g.:

```yaml
# ...
env:
  global:
    - DOC_REPO=<username>/doc
    - NEOVIM_REPO=<username>/neovim
    - NEOVIM_BRANCH=my-branch
    - secure: <output of travis encrypt>
# ...
```

After committing and pushing these changes to your PR testing branch, Travis will perform the build and push the results to `<username>/doc`. If you make changes to your PR, don't forget to rebase and push your PR testing branch so that `<username>/doc` will always be up-to-date.

