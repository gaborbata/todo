require './todo.js.rb'

todo = Todo.new

default_callback = lambda do |terminal, command, params|
  `
  try {
    var output = #{todo.execute([command] + params).to_html};
    terminal.output(output);
  } catch (error) {
    terminal.output('<span class="output"><span class="color color-31">ERROR:</span> ' + escapeHtml(error) + '</span>');
  }
  `
end

`
var escapeHtml = function(obj) {
  return (obj || '').toString().replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
};

var term = new VanillaTerminal({
  'welcome': '<u>todo list manager</u> REPL v0.1.24<br>Type "help" or "copyright" for more information.<br><br>',
  'defaultCallback': default_callback,
  'prompt': 'todo',
  'commands': {
    'cls': function(terminal) {
      terminal.clear();
    },
    'copyright': function(terminal) {
        var copyright = [
          'todo-jsonl - Copyright (c) 2020-2021 Gabor Bata',
          'opal - Copyright (c) 2013-2021 by Adam Beynon and the Opal contributors',
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

try {
  term.output(#{todo.execute(['list']).to_html});
} catch (error) {
  term.output('<span class="output"><span class="color color-31">ERROR:</span> ' + escapeHtml(error) + '</span>');
}
`
