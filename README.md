# mimir-helper

This repo contains useful command shortcuts to increase your productivity.

- Mimir-related commands start with `mimir`. Use `mimir -h` to see all available commands.
- Ram consumption-related commands start with `node-eat`. Use `node-eat -h` to see all available commands.

Feel free to modify and make your own alias. [How to create a bash alias](https://linuxize.com/post/how-to-create-bash-aliases/)

## How to Use:

### MAC

1. **Set up your custom aliases file (e.g., `.my_aliases`):**
   - Open your aliases file (such as `.my_aliases`) in your preferred text editor.
   - Copy the contents of `.bash_aliases` from this repo into your aliases file.
   - Update the `MIMIR_PATH` variable to point to your desired Mimir installation path.
   - Place your aliases file in your home directory (`~`).

2. **Source your aliases file in `.zshrc`:**
   - Add the following line to your `~/.zshrc` file if it’s not already present:
     ```sh
     [ -f "$HOME/.my_aliases" ] && source "$HOME/.my_aliases"
     ```
   - Replace `.my_aliases` with your chosen filename if different.
   - This ensures your aliases are loaded every time you open a new terminal.

3. **Reload your terminal:**
   - Either restart your terminal or run:
     ```sh
     source ~/.zshrc
     ```
   - Your custom shortcuts and aliases will now be available.

**Note:** If you have any terminal sessions open while making these changes, you must either restart those sessions or run the appropriate `source` command (as shown above) in each open terminal to ensure the aliases take effect.

### Linux / WSL setup

1. **Modify `MIMIR_PATH` in `.bash_aliases` file:**
   - Open `.bash_aliases` in your preferred text editor.
   - Locate and modify the `MIMIR_PATH` variable to point to your desired Mimir installation path.

2. **Copy the `.bash_aliases` file to your user root where `.bashrc` is located:**
   - Ensure that the `.bash_aliases` file is placed in your user root directory alongside the `.bashrc` file.

3. **Reload your terminal:**
   - Either restart your terminal or run:
     ```sh
     source ~/.bashrc
     ```
   - Your custom shortcuts and aliases will now be available.

**Note:** If you have any terminal sessions open while making these changes, you must either restart those sessions or run the appropriate `source` command (as shown above) in each open terminal to ensure the aliases take effect.
