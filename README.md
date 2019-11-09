# Marvim Bot CI

[![Build Status](https://travis-ci.org/neovim/bot-ci.svg?branch=master)](https://travis-ci.org/neovim/bot-ci)

This is the part of Marvim's planet sized brain that runs on TravisCI.
However, you won't find the "Genuine People Personalities" technology here.

# Generated Content

`bot-ci` generates or updates all of these things:

 - [Documentation/report overview page](https://neovim.io/doc)
 - Documentation:
   - [Doxygen documentation](https://neovim.io/doc/dev)
   - [User documentation](https://neovim.io/doc/user)
 - Build reports:
   - [Clang report](https://neovim.io/doc/reports/clang)
   - [PVS-studio report](https://neovim.io/doc/reports/pvs)
   - [Vimpatch report](https://neovim.io/doc/reports/vimpatch)
 - [Coverity](https://scan.coverity.com/projects/2227)
 - [Nightly builds](https://github.com/neovim/neovim/releases)
 - [Generated builds](#generated-builds)


# How it works

1. The [scripts](https://github.com/neovim/bot-ci/tree/master/ci) in this repo
   run as daily [CI jobs](https://travis-ci.org/neovim/bot-ci).
2. Some of the jobs push updates to the [neovim/doc](https://github.com/neovim/doc) repo. Examples:
   - [pvs-report.sh](https://github.com/neovim/bot-ci/blob/master/ci/pvs-report.sh) generates the [PVS report](https://neovim.io/doc/reports/pvs/PVS-studio.html.d)
   - [clang-report.sh](https://github.com/neovim/bot-ci/blob/master/ci/clang-report.sh) generates the [Clang report](https://neovim.io/doc/reports/clang/)
3. [neovim/doc](https://github.com/neovim/doc) has a `gh-pages` branch. GitHub implicitly
   creates a website for that repo, which is mapped to the `/doc/` path of the
   [main website](https://github.com/neovim/neovim.github.io).


# Building Locally

To build locally, execute `./ci/<build script>`, where `build script` is any
executable shell script. Override environment variables as necessary.

### Example: Generate the user manual HTML:

    MAKE_CMD=ninja NEOVIM_DIR=~/neovim-src/ ./ci/user-docu.sh

### Example: Generate the vim-patch report:

    VIM_SOURCE_DIR=~/vim-src/ NEOVIM_DIR=~/neovim-src/ ./ci/vimpatch-report.sh

### Example: Run the automated pull-requests task:

    VIM_SOURCE_DIR=~/neovim/.vim-src/ NEOVIM_DIR=~/neovim-src/ ./ci/auto-pullrequest.sh

# Testing PRs

Building of PRs is disabled for this repository; builds would always fail
because of [Travis's security restrictions][travis-security].
You can test your changes in a different way, though. Here's an example on how
to test `neovim/doc`-related changes using Travis CI:

 * Fork the `neovim/doc` repository to `<username>/doc`.
 * Using your `neovim/bot-ci` fork:
   * Enable Travis CI.
   * Create a new testing branch based on your PR branch (e.g. `git checkout
     pr-branch && git checkout -b pr-branch-test`).
   * Obtain a [Github personal access token](https://github.com/settings/applications)
     and encrypt it for Travis using `travis encrypt 'GH_TOKEN=<token>' -r
     <username>/bot-ci`.
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

After committing and pushing these changes to your PR testing branch, Travis
will perform the build and push the results to `<username>/doc`. If you make
changes to your PR, don't forget to rebase and push your PR testing branch so
that `<username>/doc` will always be up-to-date.

The above steps can be performed analogously for other repositories a `bot-ci`
script pushes to, e.g. `neovim/deps` for `ci/deps64.sh`.

# Generated builds

The `ci/nightly.sh` script auto-generates and publishes builds to
https://github.com/neovim/neovim/releases/nightly.

## Setting up integration builds

This repo provides a script to download and set up the 64-bit Linux build of
Neovim on Travis CI. In the future, it may be extended to support different
versions and operating systems.

To use the script in a Travis build, download and evaluate it in `.travis.yml`:

```yaml
# ...
before_install:
  - eval "$(curl -Ss https://raw.githubusercontent.com/neovim/bot-ci/master/scripts/travis-setup.sh) nightly-x64"
# ...
script:
  # `nvim` has been added to `$PATH` by the setup script.
  - nvim ...
```

For an example see the [Python-client `.travis.yml`](https://github.com/neovim/python-client/blob/master/.travis.yml).


[travis-security]: http://docs.travis-ci.com/user/pull-requests/#Security-Restrictions-when-testing-Pull-Requests
