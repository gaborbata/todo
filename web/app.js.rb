require './todo.js.rb'

todo = Todo.new

default_callback = lambda do |terminal, command, params|
  `terminal.output(#{todo.execute([command] + params).to_html})`
end

`
var term = new VanillaTerminal({
  'welcome': '<u>todo list manager</u> REPL v1.0.8<br>Type "help" or "copyright" for more information.<br><br>',
  'defaultCallback': default_callback,
  'prompt': 'todo',
  'commands': {
    'cls': function(terminal) {
      terminal.clear();
    },
    'copyright': function(terminal) {
        var copyright = [
          'todo-jsonl - Copyright (c) 2020-2021 Gabor Bata',
          'opal - Copyright (c) 2013-2021 Adam Beynon and the Opal contributors',
          'vanilla-terminal - Copyright (c) 2018 Javier Jimenez Villar'
        ].join('<br>');
        terminal.output('<span class="output">' + copyright + '</span>');
    },
    'wipe': function(terminal) {
      terminal.prompt('Are you sure remove all your todo data? y/n', function(value) {
        if (value.trim().toUpperCase() === 'Y') {
          localStorage.removeItem(#{Todo::TODO_FILE});
          terminal.history = [];
          terminal.historyCursor = 0;
          terminal.output('todo data wiped');
        }
      });
    }
  }
});

term.output(#{todo.execute(['list']).to_html});
`
