DOC_SUBTREE="/index.html"
INDEX_PAGE_URL=http://neovim.org/doc_index

generate_doc_index() {
  echo "Updating index.html from ${INDEX_PAGE_URL}."
  wget -q ${INDEX_PAGE_URL} -O ${DOC_DIR}/index.html
}
