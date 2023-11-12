# doc/: Generated docs and reports for Neovim

This repo contains automation scripts and CI configuration to run the scripts.

- The CI job runs the scripts which generate stuff, which is committed to the
  [**gh-pages** branch](https://github.com/neovim/doc/tree/gh-pages).
    - GitHub implicitly creates a website from that branch, mapped to the
      `/doc/` path of the [main website](https://github.com/neovim/neovim.github.io).
- Some assets are served at https://neovim.io/doc
    - [doc/ landing page](https://neovim.io/doc)
        - [user/ docs](https://neovim.io/doc/user)
    - Build reports:
        - [Clang report](https://neovim.io/doc/reports/clang)
        - [Vimpatch report](https://neovim.io/doc/reports/vimpatch)

## Run Locally

To run the scripts locally, execute `./ci/<build script>`, where `build script`
is any executable shell script. Override environment variables as necessary.

### Example: Generate the vim-patch report:

    VIM_SOURCE_DIR=~/vim-src/ NEOVIM_DIR=~/neovim-src/ ./ci/vimpatch-report.sh
