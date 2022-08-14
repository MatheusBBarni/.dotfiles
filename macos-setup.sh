echo 'Here we go again!'

echo 'Installing brew'
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew update

echo 'Installing productivity apps'
brew install nvm
brew install pnpm
brew install starship
brew install rectangle
brew install --cask raycast
brew install alt-tab
brew install stats
brew install itsycal
brew install neovim

nvm install v16.16.0
nvm alias default v16.16.0

npm i -g yarn@1.22.19
