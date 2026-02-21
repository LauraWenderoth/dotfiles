# dotfiles

Personal configuration files for my development setup.

## VS Code Settings

1. Open Preferences: Open User Settings (JSON) in VS Code. (Shift, command, p + search for user settings)
2. Copy the contents of `vscode/settings.json` from this repository and paste it into your User Settings (JSON) file in VS Code.
3. Save the file to apply the new settings.

## Ubuntu Dotfiles Installation

How to use this setup script:

1. Open a terminal and change to the directory where this script is located:

   ```
   cd $YOUR_DOTFILES_DIRECTORY/zsh
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

## Mac OS Zsh Installation

cd $YOUR_DOTFILES_DIRECTORY/zsh
chmod +x macos-install.sh
bash -x ./macos-install.sh
exec zsh

### Problems with  ~/.zshrc

Could not find ~/.zshrc, creating one and copying template from dotfiles. Was failing. touch ~/.zshrc

1. rm ~/.zshrc
2. cp /PATH/dotfiles/zsh/.zshrc ~/.zshrc
3. touch ~/.zshrc
