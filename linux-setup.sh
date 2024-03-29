echo 'Here we go again!'

echo 'To start, we will need git, so lets go'
sudo apt-get install git-all

echo 'First we are going do install Tilix'
sudo apt-get install -y tilix

echo 'Now let`s install Dracula theme for Tilix'
sudo mkdir ~/.config/tilix/schemes
wget "https://github.com/dracula/tilix/archive/master.zip"
unzip master.zip
mv tilix-master/Dracula.json ~/.config/tilix/schemes
sudo rm -r tilix-master

clear

echo 'Let`s install curl'
sudo apt-get install -y curl

clear

echo 'We are going to install zsh and oh-my-zsh'
sudo apt install -y zsh
chsh -s $(which zsh)
echo $SHELL
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

clear

echo 'Now let`s install some zsh plugins'
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions

clear

echo 'Let`s install Spotify'
sudo snap install -y spotify

clear

echo 'Let`s install now vsode'
echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | sudo \
   tee /etc/apt/sources.list.d/vs-code.list
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo apt-get update
sudo apt-get install -y code

clear

echo 'Now with curl, let`s install nodeJS'
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

clear

echo 'After installing node, we will install NVM'
sudo apt-get update
sudo apt-get install -y build-essential libssl-dev
curl https://raw.githubusercontent.com/creationix/nvm/v0.35.3/install.sh | bash
source ~/.profile

clear

echo 'Intalling go'
GO_FILE=go1.17.5.linux-amd64.tar.gz
wget https://go.dev/dl/$GO_FILE
sudo tar -xvf $GO_FILE
sudo mv go /usr/local

echo 'Remember to put the content of yours personal-zshrc on the .zshrc'


