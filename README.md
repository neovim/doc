# doc/: Generated docs and reports for Neovim

> [!WARNING]  
> This repo is no longer needed since https://github.com/neovim/neovim.github.io/pull/437.
> 
> Instead the website repo (`neovim/neovim.github.io`), plus scripts in `neovim/neovim`, generate reports as needed.

This repo contains automation scripts and CI configuration to run the scripts.

- The CI job runs the scripts which generate stuff, which is committed to the
  [**gh-pages** branch](https://github.com/neovim/doc/tree/gh-pages).
    - GitHub implicitly creates a website from that branch, mapped to the
      `/doc/` path of the [main website](https://github.com/neovim/neovim.github.io).
- Some assets are served at https://neovim.io/doc
    - [doc/ landing page](https://neovim.io/doc)
        - [user/ docs](https://neovim.io/doc/user)

## Run Locally

To run the scripts locally, execute `./ci/<build script>`, where `build script`
is any executable shell script. Override environment variables as necessary.

### Example: Build user documentations:

    NEOVIM_DIR=~/neovim-src/ ./ci/user-docu.sh
