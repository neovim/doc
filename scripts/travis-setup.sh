nightly-x64() {
  mkdir "$TRAVIS_BUILD_DIR/_neovim"
  wget -q -O - https://github.com/neovim/neovim/releases/download/nightly/neovim-linux64.tar.gz \
    | tar xzf - --strip-components=1 -C "$TRAVIS_BUILD_DIR/_neovim"

  export PATH="$TRAVIS_BUILD_DIR/_neovim/bin:$PATH"
  echo "\$PATH: \"$PATH\""

  export VIM="$TRAVIS_BUILD_DIR/_neovim/share/nvim/runtime"
  echo "\$VIM: \"$VIM\""

  nvim --version
}

"$@"
