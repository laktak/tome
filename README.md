
# TOME

Playbooks for your Terminal AKA "Your history is history!"

TOME is a notcronym for tmux-vim-terminal-playbooks and maybe slightly better than "TVITP".


## Goals

- Provide a list of commands to execute (a "playbook").
- Easily execute these commands in any REPL (a system shell, ssh, a database client, etc.)
- Manage these playbooks per project.
- Bonus: completely replace the shell command history.


## Introduction

After installing the plugins, press `<tmux-prefix>+p`, this will split the current pane vertically and create or open a playbook in vim.

A playbook is a mixture of command history and script. It contains a list of commands that you can execute interactively in any order for any terminal application.

```
ls *.jpg
convert input.jpg output.png
convert input.jpg -resize 200x200 output.jpg
convert input.jpg -crop 200x200+50+50 output.jpg
convert input.jpg -rotate 90 output.jpg
```

You can send (execute) the commands to the target, which is a tmux pane following the playbook. Usually you use `Enter` to execute one line. It's also possible to execute a selection or paragraph (`<Leader>p` and `<Leader>P`).

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

While playbooks are organized by projects in folders, the target's location can be anywhere. You can also make any document into a temporary playbook with the `:TomePlayBook` command.


## Requirements

- tmux
- vim
- any REPL, e.g. bash, a database client, etc.

## Installation

### vim plugin

Add laktak/tome to your favorite plugin manager.

E.g. for [vim-plug](https://github.com/junegunn/vim-plug/) place this in your .vimrc:

    Plug 'laktak/tome'

then run the following in Vim:

    :source %
    :PlugInstall


### tmux plugin

To install tome with the [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) simply add the plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'laktak/tome'

then and hit `prefix + I` to fetch the plugin and source it.


To install it manually, first clone the repo:

    $ git clone https://github.com/laktak/tome ~/.tmux/tome

Add this line to the bottom of `.tmux.conf`:

    run-shell ~/.tmux/tome/tome.tmux

Reload the tmux environment:

    # type this in terminal
    $ tmux source-file ~/.tmux.conf


## Configuration


### vim options

By default Tome has the following mappings:

    nmap <Leader>p <Plug>(TomePlayLine)
    nmap <Leader>P <Plug>(TomePlayParagraph)
    xmap <Leader>p <Plug>(TomePlaySelection)

If you prefer to create them yourself set

    let g:tome_no_mappings = 1

Tome has a no send list to avoid accidentially sending input to a tui application. By default this includes `lf` (the file manager) and `vim`. Set your own list with

    let g:tome_no_send = ['vim', 'lf', 'gitui']


### tmux options

You can set any of these options by adding them to your `~/.tmux.conf` file:

    set -g <option> "<value>"

Where `<option>` and `<value>` correspond to one of the options specified below

### Keys

| Option                 | Default         | Description |
| :---                   | :---:           | :--- |
| `@tome_key`            | `p`             | The key binding to open a tome playbook. |
| `@tome_height`         | `8`             | Height of the playbook vertial split. |
| `@tome_playbook`       | `.playbook.sh`  | Name of the playbook to open. |

