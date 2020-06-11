#!/usr/bin

echo 'Here we go again!'

echo 'First we are going to install zsh and oh-my-zsh'
sudo apt install zsh
chsh -s $(which zsh)
echo $SHELL
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo 'Now let`s install some zsh plugins'
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

echo 'Let`s install spotify Spotify'
sudo snap install spotify

echo 'Let`s install now vsode'
echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | sudo \
   tee /etc/apt/sources.list.d/vs-code.list
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo apt-get update
sudo apt-get install code

echo 'Let`s install curl'
sudo apt-get install curl

echo 'Now with curl, let`s install nodeJS'
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install nodejs

echo 'After installing node, we will install NVM'
sudo apt-get update
sudo apt-get install build-essential libssl-dev
curl https://raw.githubusercontent.com/creationix/nvm/v0.35.3/install.sh | bash
source ~/.profile

echo 'Remember to put the content of yours personal-zshrc on the .zshrc'
