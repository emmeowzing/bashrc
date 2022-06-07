#! /bin/bash
# Link this repository to ~/.bash_functions and ~/.bash_aliases.

if [ ! -f ~/.bash_functions ]; then
    ln -s "$(pwd)/.bash_functions.sh" ~/.bash_functions
else
    printf "INFO: Skipping link to ~/.bash_functions, file already exists.\\n"
fi

if [ ! -f ~/.bash_aliases ]; then
    ln -s "$(pwd)/.bash_aliases.sh" ~/.bash_aliases
else
    printf "INFO: Skipping link to ~/.bash_aliases, file already exists.\\n"
fi

if [ "$(grep "source ~/.bash_functions" ~/.bashrc)" = "" ]; then
    printf "source ~/.bash_functions\\n" >> ~/.bashrc
fi