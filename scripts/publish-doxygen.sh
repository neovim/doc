# this script is based on:
# http://philipuren.com/serendipity/index.php?/archives/21-Using-Travis-to-automatically-publish-documentation.html
# the following automatically builds the doxygen documentation and pushes
# it to the gh_pages branch on the neovim/doc repo

# install doxygen
cd /opt
sudo wget http://ftp.stack.nl/pub/users/dimitri/doxygen-1.8.7.linux.bin.tar.gz
sudo tar -xzvf doxygen-1.8.7.linux.bin.tar.gz
export PATH="/opt/doxygen-1.8.7/bin:$PATH"
cd $TRAVIS_BUILD_DIR

# First, set up credentials using the environment variables
# GIT_NAME and GIT_EMAIL.
git config --global user.name "${GIT_NAME}"
git config --global user.email ${GIT_EMAIL}

mkdir repos

# clone the neovim/neovim repo
git clone https://github.com/neovim/neovim ./repos/neovim

# clone the neovim/doc and switch to gh_pages branch
git clone --branch gh-pages https://github.com/neovim/doc ./repos/doc

# delete the old doxygen folder
rm -rf ./repos/doc/doxygen

# build the documentation
cd repos/neovim
mkdir build
doxygen

# move the generated docs into the doc repo
mv build/doxygen/html ../doc/doxygen

# cd into the doc dir and commit and push the new docs.
# GH_TOKEN was passed encrypted to travis and should have been decrypted
# using travis' private key before this script was run.
cd ../doc
git add --all .
git commit -m "auto-updating development documentation"
git push https://${GH_TOKEN}@github.com/neovim/doc gh-pages-test

