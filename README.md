# todo

todo list manager inspired by [todo.txt](http://todotxt.org) using the [jsonl](http://jsonlines.org) format

```
Usage: todo <command> <arguments>

Commands:
* add <text>                     add new task
* start <tasknumber>             mark task as started
* done <tasknumber>              mark task as completed
* block <tasknumber>             mark task as blocked

* append <tasknumber> <text>     append text to task title
* replace <tasknumber> <text>    replace task
* del <tasknumber>               delete task
* note <tasknumber> <text>       add note to task

* list <regexp>                  list tasks (only not completed by default)
* show <tasknumber>              show all task details
* help                           this help screen
```

## Demo

![todo](todo.gif)

## Requirements

Ruby 2.6 or newer
