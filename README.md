# dotfiles
Personal configuration files for my development setup.

## Ubuntu Dotfiles Installation 

How to use this setup script:

1. Open a terminal and change to the directory where this script is located:
   ```
   cd $YOUR_DOTFILES_DIRECTORY
   ```
2. Make the script executable:
   ```
   chmod +x ubuntuinstall.sh
   ```
3. Run the installation script:
   ```
   ./ubuntuinstall.sh
   ```

This will:
- Install Zsh, Oh My Zsh, and useful plugins
- Link my `.zshrc` from the `zsh` folder in this repository to your home directory
- Set Zsh as the default shell

After the script finishes, start a new terminal or run `exec zsh` to load your new configuration.

## Errors 
If you encounter : `$HOME$.zshrc:source:90: no such file or directory: $HOMEE.oh-my-zsh/oh-my-zsh.sh`

Remove oh my zsh and reinstall by running:
```
rm -rf ~/.oh-my-zsh
rm -f ~/.zshrc
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

Than rerun config script.