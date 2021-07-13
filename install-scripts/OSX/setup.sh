#==============
# Install all the packages
#==============

# So we use all of the packages we are about to install
# echo "export PATH='/usr/local/bin:$PATH'\n" >> ~/.zshrc
# source ~/.zshrc

#==============
# Remove old dot flies
#==============
sudo rm -rf ~/.vim > /dev/null 2>&1
sudo rm -rf ~/.vimrc > /dev/null 2>&1
sudo rm -rf ~/.tmux.conf > /dev/null 2>&1
sudo rm -rf ~/.tmux.conf.local > /dev/null 2>&1
sudo rm -rf ~/.zshrc > /dev/null 2>&1
sudo rm -rf ~/.gitconfig > /dev/null 2>&1
sudo rm -rf ~/.config > /dev/null 2>&1

#==============
# Create symlinks in the home folder
# Allow overriding with files of matching names in the custom-configs dir
#==============
SYMLINKS=()
ln -sf ~/.cfg/.vim ~/.vim
SYMLINKS+=('.vim')
ln -sf ~/.cfg/.vimrc ~/.vimrc
SYMLINKS+=('.vimrc')
ln -sf ~/.cfg/.zshrc ~/.zshrc
SYMLINKS+=('.zshrc')
ln -sf ~/.cfg/.config ~/.config
SYMLINKS+=('.config')
ln -s ~/.cfg/.gitconfig ~/.gitconfig
SYMLINKS+=('.gitconfig')
ln -s ~/.cfg/.tmux.conf ~/.tmux.conf
SYMLINKS+=('.tmux.conf')
ln -s ~/.cfg/.tmux.conf.local ~/.tmux.conf.local
SYMLINKS+=('.tmux.conf.local')

echo ${SYMLINKS[@]}

#==============
# And we are done
#==============
echo -e "\n====== All Done!! ======\n"
