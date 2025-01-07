
# 🔁 TOME Playbooks

Playbooks are a simple but powerful tool for your shell and terminal apps.

1. Replaces your command history, organized by project
2. Allows interactive scripting
3. Allows you to add notes - we may even call it documentation ;)
4. Enhances your shell prompt with Vim
5. Built for tmux or the Vim terminal

![intro](https://github.com/laktak/tome/wiki/assets/intro1.gif)


- [Introduction](#introduction)
- [Requirements](#requirements)
- [Installation](#installation)
  - [vim plugin](#vim-plugin)
  - [tmux plugin (optional)](#tmux-plugin-optional)
- [Scripting](#scripting)
- [Configuration](#configuration)
  - [vim options](#vim-options)
  - [tmux options](#tmux-options)


## Introduction

- With tmux: press `<tmux-prefix> p` (default binding), this will split the current pane vertically and create or open a playbook in vim
- With Vim only: run `vim .playbook.sh` or open a playbook file

A playbook is a mixture of command history, script and documentation. You can structure it however you like. On any line that you want to send to the terminal just press enter. This can be any shell but also a terminal application like a SQL client or ssh to a remote server.

```
ls *.jpg
convert input.jpg output.png
convert input.jpg -resize 200x200 output.jpg
convert input.jpg -crop 200x200+50+50 output.jpg
convert input.jpg -rotate 90 output.jpg
```

You can send (execute) the commands to the target, which is a tmux pane following the playbook. Usually you use `<Enter>` to execute one line. It's also possible to execute a selection or paragraph (`<Leader>p` and `<Leader>P`).

Treat your playbook like notes for a project. Unlike your shell history you can start a docker container, open a database client or even ssh to a remote system and then proceed to send commands to the executing application.

```
# connect remote
ssh myserver

# run psql
psql "host=localhost port=5432 dbname=postgres user=pg password=pg sslmode=disable"
psql "host=dbserver port=5432 dbname=postgres user=pg password=pg"

# run a query
select * from foo where bar='red';

# insert data etc.
insert into foo(bar, result) values('blue', 42);
```


While playbooks are organized by projects in folders, the target's location can be anywhere (meaning you can include a `cd` to another location in your playbook).

You can also make any document (like this README) into a temporary playbook by using the `<Leader>p` key bindings or enabling `<Enter>` with the `:TomePlayBook` command.

Note: the $ indicator at the beginning of a line for shell commands (like in some READMEs) will be ignored so you can run the command directly.


Your shell already has variables so typically you would not need them in Tome.

```
# this Bash example defines BASE with a constant
export BASE=http://localhost:8080
# and TOKEN using a shell script
export TOKEN=$(token-request)
# "call" can be another script or defined directly in Tome:
call() { http -A bearer -a $TOKEN "$@"; }

# use everything together
id=$(call $BASE/car name==foostang | jq .[0].id)
call $BASE/car/$id
  call PUT $BASE/car/$id color=blue
```

If you prefer, or if the target has no variables, you can use Tome variables (string replacement only).

- Variables are enclosed in `$<` and `>`, like `$<foo>`.
- Variables are defined with `$<NAME>=VALUE`, like `$<foo>=some text`.
- Any variable is replaced with its defined value, no other operations are performed.
- If a variable is undefined Tome will open a scratchpad with the missing variables. Don't forget to send the values with `<Enter>`!
- To escape the text `$<text>` use `$<<text>`

```
# set a BASE variable
$<base>=http://localhost:8080
# use in a command
echo $<base>
# undefined variables open a scratchpad
echo $<foo>
# escaped, not a variable
echo "$<<foo>"
```

On tmux: if you want a temporary scratch pad press `<tmux-prefix> P`. It is also a good idea to paste commands here instead of directly into the terminal.

When you want multiple playbooks in a project just prefix them with `.playbook-`, e.g. `.playbook-db.sql` with the correct extension to get syntax highlighting.


## Requirements

- vim or neovim
- any REPL, e.g. bash, a database client, etc.
- tmux optional (but recommended)


## Installation

### vim plugin

Add laktak/tome to your favorite plugin manager.

E.g. for [vim-plug](https://github.com/junegunn/vim-plug/) place this in your .vimrc:

```
Plug 'laktak/tome'
```

then run the following in Vim:

```
:source %
:PlugInstall
```


### tmux plugin (optional)

To install Tome with the [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) simply add the plugin to the list of TPM plugins in `.tmux.conf`:

```
set -g @plugin 'laktak/tome'
```

then and hit `<tmux-prefix> I` to fetch the plugin and source it.


To install it manually, first clone the repo:

```
$ git clone https://github.com/laktak/tome ~/.tmux/tome
```

Add this line to the bottom of `.tmux.conf`:

```
run-shell ~/.tmux/tome/tome.tmux
```

Reload the tmux environment:

```
# type this in terminal
$ tmux source-file ~/.tmux.conf
```


## Scripting

If you want to open a playbook from a script you can use the `tome-open-playbook` command. It can be found where you installed the tmux plugin.

```
Usage: tome-open-playbook [-s] [-l height]
```

- `-s` will open a scratchpad
- `-l` allows you to specify a height


## Configuration


### vim options

By default Tome has the following mappings:

```
nmap <Leader>p <Plug>(TomePlayLine)
nmap <Leader>P <Plug>(TomePlayParagraph)
xmap <Leader>p <Plug>(TomePlaySelection)
```

[See `help TomeConfig`](doc/tome.txt) in Vim to change them, and for more options.


### tmux options

You can set any of these options by adding them to your `~/.tmux.conf` file:

```
set -g <option> "<value>"
```

Where `<option>` and `<value>` correspond to one of the options specified below

| Option                 | Default         | Description |
| :---                   | :---:           | :--- |
| `@tome_key`            | `p`             | The key binding to open a Tome playbook. |
| `@tome_scratch_key`    | `P`             | The key binding to open a Tome scratchpad. |
| `@tome_height`         | `8`             | Height of the playbook vertial split. |
| `@tome_playbook`       | `.playbook.sh`  | Name of the playbook to open. |


