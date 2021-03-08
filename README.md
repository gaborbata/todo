# todo [![Build Status](https://travis-ci.org/gaborbata/todo.svg?branch=master)](https://travis-ci.org/gaborbata/todo) [![Run tests](https://github.com/gaborbata/todo/workflows/Run%20tests/badge.svg)](https://github.com/gaborbata/todo/actions/workflows/ruby.yml)

todo list manager inspired by [todo.txt](http://todotxt.org) using the [jsonl](http://jsonlines.org) format

```
Usage: todo <command> <arguments>

Commands:
* add <text>                     add new task
* start <tasknumber> [text]      mark task as started, with optional note
* done <tasknumber> [text]       mark task as completed, with optional note
* block <tasknumber> [text]      mark task as blocked, with optional note
* reset <tasknumber> [text]      reset task to new state, with optional note
* prio <tasknumber> [text]       toggle high priority flag, with optional note
* due <tasknumber> [date]        set/unset due date (in YYYY-MM-DD format)

* append <tasknumber> <text>     append text to task title
* rename <tasknumber> <text>     rename task
* del <tasknumber>               delete task
* note <tasknumber> <text>       add note to task
* delnote <tasknumber>           delete all notes from task

* list <regex> [regex...]        list tasks (only active tasks by default)
* show <tasknumber>              show all task details
* repl                           enter read-eval-print loop mode
* cleanup <regex> [regex...]     cleanup completed tasks by regex
* help                           this help screen

With list command the following pre-defined regex patterns can be also used:
:active, :done, :blocked, :started, :new, :all, :today, :tomorrow, :next7days

Due dates can be also added via tags in task title: "due:YYYY-MM-DD"

Legend:
new [ ], done [x], started [>], blocked [!], priority *
```

`todo.jsonl` file stores the todo data which is saved into the `$HOME` folder of the current user.

## How to install

```
gem install todo-jsonl
```

## Demo

Web: [todo JavaScript REPL](http://gaborbata.github.io/todo/) using browser local storage
(created with [Opal](https://github.com/opal/opal) and [vanilla-terminal](https://github.com/soyjavi/vanilla-terminal))

Screencast:

![todo](todo.gif)

## Requirements

Ruby 2.5 or newer
