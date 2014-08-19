DOC_SUBTREE="/dev/"

generate_doxygen() {
  cd ${NEOVIM_DIR}

  mkdir -p build
  doxygen

  rm -rf ${DOC_DIR}/dev
  mv build/doxygen/html ${DOC_DIR}/dev
}
