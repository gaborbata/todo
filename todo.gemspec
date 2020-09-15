Gem::Specification.new do |s|
  s.name        = 'todo-jsonl'
  s.version     = '0.1.0'
  s.date        = '2020-09-15'
  s.summary     = 'todo list manager inspired by todo.txt using the jsonl format'
  s.description = <<-EOF
    Usage: todo <command> <arguments>

    Commands:
    * add <text>                     add new task
    * start <tasknumber>             mark task as started
    * done <tasknumber>              mark task as completed
    * block <tasknumber>             mark task as blocked
    * prio <tasknumber>              toggle high priority flag

    * append <tasknumber> <text>     append text to task title
    * rename <tasknumber> <text>     rename task
    * del <tasknumber>               delete task
    * note <tasknumber> <text>       add note to task
    * delnote <tasknumber> <text>    delete all notes from task

    * list <regex> [regex...]        list tasks (only active tasks by default)
    * show <tasknumber>              show all task details
    * repl                           enter read–eval–print loop mode
    * help                           this help screen

    With list command the following pre-defined regex patterns can be also used:
    :active, :done, :blocked, :started, :new, :all

    Legend:
    new [ ], done [x], started [>], blocked [!], priority *
  EOF
  s.authors     = ['Gabor Bata']
  s.homepage    = 'https://github.com/gaborbata/todo'
  s.license     = 'MIT'
  s.executables = ['todo.rb', 'todo']
end
