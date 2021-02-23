### bashrc

A place where I store my custom `.bashrc` functions and aliased shortcuts. 

Most of these have been written with a very narrow application in mind. For example, 
`allocate` just creates a raw, empty, virtual disk (with `dd`) in a ZFS mount point 
that I can then reference in a qemu XML template (I tend to do this a lot, so it 
saves me time).

#### How I use them

I'll typically clone out this repo, then link
```shell script
ln -s /path/to/repo/.bash_functions.sh ~/.bash_functions 
ln -s /path/to/repo/.bash_aliases.sh ~/.bash_aliases
```
and, finally,
```shell script
printf "source ~/.bash_functions\\n" >> ~/.bashrc
```
so that it may be referenced (`.bash_aliases` is automatically loaded), and updates captured over the links.