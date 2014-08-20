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

To generate individual reports locally, execute a command similar to the following:

```bash
REPORT=vimpatch-report ./scripts/publish-docs.sh
```

To see which report types are available, have a look at the contents of `./scripts/`.
