# todo for Node.js [![npm version](https://badge.fury.io/js/todo-jsonl.svg)](https://badge.fury.io/js/todo-jsonl)

todo list manager on the command-line inspired by [todo.txt](http://todotxt.org) using the [jsonl](http://jsonlines.org) format

The Node.js version is compiled with [Opal](https://github.com/opal/opal) from the original [todo](https://github.com/gaborbata/todo) Ruby script,
with some JavaScript-specific modifications, optimized with [Closure Compiler](https://github.com/google/closure-compiler)

```
Usage: todo <command> <arguments>

Commands:
* add <text>                     add new task
* start <tasknumber> [text]      mark task as started, with optional note
* done <tasknumber> [text]       mark task as completed, with optional note
* block <tasknumber> [text]      mark task as blocked, with optional note
* wait <tasknumber> [text]       mark task as waiting, with optional note
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
:active, :done, :blocked, :waiting, :started, :new, :all, :priority,
:note, :today, :tomorrow, :next7days, :overdue, :due, :recent

Due dates can be also added via tags in task title: "due:YYYY-MM-DD"
In addition to formatted dates, you can use date synonyms:
"due:today", "due:tomorrow", and day names e.g. "due:monday" or "due:tue"

Legend: new [ ], done [x], started [>], blocked [!], waiting [@], priority *
```

`todo.jsonl` file stores the todo data which is saved into the `$HOME` folder of the current user.

## How to install

```
npm install -g todo-jsonl
```

## Demo

[todo JavaScript REPL](http://gaborbata.github.io/todo/) using browser local storage

Screencast:

![todo](https://raw.githubusercontent.com/gaborbata/todo/master/todo.gif)
