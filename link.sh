#! /bin/bash
# Link this repository to ~/.bash_functions and ~/.bash_aliases, alongside your ~/.bashrc.


# Add links to the current git repository so versioning can be applied to your functions and aliases.
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


# Add references to ~/.bash_{functions,aliases} automatically to ~/.bashrc or ~/.zshrc.
if [ -f ~/.zshrc ]; then
    if [ "$(grep "source ~/.bash_functions" ~/.zshrc)" = "" ] || [ "$(grep ". ~/.bash_functions" ~/.zshrc)" = "" ]; then
        printf "source ~/.bash_functions\\n" >> ~/.zshrc
    fi

    if [ "$(grep "source ~/.bash_aliases" ~/.zshrc)" = "" ] || [ "$(grep ". ~/.bash_aliases" ~/.zshrc)" = "" ]; then
        printf "source ~/.bash_aliases\\n" >> ~/.zshrc
    fi
elif [ -f ~/.bashrc ]; then
    if [ "$(grep "source ~/.bash_functions" ~/.bashrc)" = "" ] || [ "$(grep ". ~/.bash_functions" ~/.bashrc)" = "" ]; then
        printf "source ~/.bash_functions\\n" >> ~/.bashrc
    fi

    if [ "$(grep "source ~/.bash_aliases" ~/.bashrc)" = "" ] || [ "$(grep ". ~/.bash_aliases" ~/.bashrc)" = "" ]; then
        printf "source ~/.bash_aliases\\n" >> ~/.bashrc
    fi
fi
