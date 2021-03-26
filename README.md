# todo [![Build Status](https://travis-ci.org/gaborbata/todo.svg?branch=master)](https://travis-ci.org/gaborbata/todo) [![Run tests](https://github.com/gaborbata/todo/workflows/Run%20tests/badge.svg)](https://github.com/gaborbata/todo/actions/workflows/ruby.yml)

todo list manager on the command-line inspired by [todo.txt](http://todotxt.org) using the [jsonl](http://jsonlines.org) format

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
* delnote <tasknumber> [number]  delete a specific or all notes from task

* list <regex> [regex...]        list tasks (only active tasks by default)
* show <tasknumber>              show all task details
* repl                           enter read-eval-print loop mode
* cleanup <regex> [regex...]     cleanup completed tasks by regex
* help                           this help screen

With list command the following pre-defined queries can be also used:
:active, :done, :blocked, :started, :new, :all, :priority, :note,
:today, :tomorrow, :next7days, :overdue, :due, :recent

Due dates can be also added via tags in task title: "due:YYYY-MM-DD"
In addition to formatted dates, you can use date synonyms:
"due:today", "due:tomorrow", and day names e.g. "due:monday" or "due:tue"

Legend: new [ ], done [x], started [>], blocked [!], priority *
```

`todo.jsonl` file stores the todo data which is saved into the `$HOME` folder of the current user.

## How to install

```
gem install todo-jsonl
```

## Requirements

Ruby 2.5 or newer, or JRuby

## Demo

[todo JavaScript REPL](http://gaborbata.github.io/todo/) using browser local storage

Screencast:

![todo](https://raw.githubusercontent.com/gaborbata/todo/master/todo.gif)

## Other versions

* [todo for Node.js](https://github.com/gaborbata/todo/tree/master/node)
  compiled with [Opal](https://github.com/opal/opal)
* [todo for web](http://gaborbata.github.io/todo/) using browser local storage,
  created with [Opal](https://github.com/opal/opal) and [Vanilla Terminal](https://github.com/soyjavi/vanilla-terminal)
