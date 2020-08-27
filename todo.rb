#!/usr/bin/env ruby

# todo.rb - todo list manager inspired by todo.txt using the jsonl format.
#
# Copyright (c) 2020 Gabor Bata
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'json'

DATE_FORMAT = '%Y-%m-%d'

COLOR_CODES = {
  black:   30,
  red:     31,
  green:   32,
  yellow:  33,
  blue:    34,
  magenta: 35,
  cyan:    36,
  white:   37
}

STATES = {
  'new'  => '[ ]',
  'done' => '[x]',
  'started' => '[>]',
  'blocked' => '[!]',
  'default' => '[?]'
}

PRIO = {
  'new'     => 3,
  'done'    => 4,
  'started' => 2,
  'blocked' => 1,
  'default' => 100
}

COLORS = {
  'new'     => :white,
  'done'    => :blue,
  'started' => :green,
  'blocked' => :yellow,
  'default' => :magenta
}

TODO_FILE = "#{ENV["HOME"]}/todo.jsonl"

def usage
  <<~USAGE
    Usage: todo <command> <arguments>

    Commands:
    * add <text>                     add new task
    * start <tasknumber>             mark task as started
    * done <tasknumber>              mark task as completed
    * block <tasknumber>             mark task as blocked
    * prio <tasknumber>              toggle high priority flag

    * append <tasknumber> <text>     append text to task title
    * replace <tasknumber> <text>    replace task
    * del <tasknumber>               delete task
    * note <tasknumber> <text>       add note to task

    * list <regexp>                  list tasks (only not completed by default)
    * show <tasknumber>              show all task details
    * help                           this help screen
   USAGE
end

def get_tasks
  count = 0
  tasks = {}
  if File.exist?(TODO_FILE)
    File.open(TODO_FILE, 'r:UTF-8') do |file|
      file.each_line do |line|
        next if line.strip == ''
        count += 1
        tasks[count] = JSON.parse(line.chomp)
      end
    end
  end
  tasks
end

def write_tasks(tasks)
  keys = tasks.keys.sort
  file = File.open(TODO_FILE, 'w:UTF-8')
  keys.each do |key|
    file.write(JSON.generate(tasks[key]) + "\n")
  end
  file.close
end

def add(text)
  file = File.open(TODO_FILE, 'a:UTF-8')
  task = {
    'state' => 'new',
    'title' => text,
    'modified' => Time.now.strftime(DATE_FORMAT)
  }
  file.write(JSON.generate(task) + "\n")
  file.close
  list
end

def append(item, text = '')
  tasks = get_tasks
  check_item(tasks, item)
  tasks[item]['title'] = [tasks[item]['title'], text].join(' ')
  tasks[item]['modified'] = Time.now.strftime(DATE_FORMAT)
  write_tasks(tasks)
  list(tasks)
end

def replace(item, text)
  tasks = get_tasks
  check_item(tasks, item)
  tasks[item] = {
    'state' => 'new',
    'title' => text,
    'modified' => Time.now.strftime(DATE_FORMAT)
  }
  write_tasks(tasks)
  list(tasks)
end

def delete(item)
  tasks = get_tasks
  check_item(tasks, item)
  tasks.delete(item)
  write_tasks(tasks)
  list
end

def change_state(item, state)
  tasks = get_tasks
  check_item(tasks, item)
  tasks[item]['state'] = state
  tasks[item]['modified'] = Time.now.strftime(DATE_FORMAT)
  write_tasks(tasks)
  list(tasks)
end

def set_priority(item)
  tasks = get_tasks
  check_item(tasks, item)
  tasks[item]['priority'] = !tasks[item]['priority']
  tasks[item]['modified'] = Time.now.strftime(DATE_FORMAT)
  write_tasks(tasks)
  list(tasks)
end

def list(tasks_map = nil, patterns = nil)
  items = {}
  tasks = tasks_map || get_tasks
  search_patterns = patterns.nil? || patterns.empty? ? ['state=(new|started|blocked)'] : patterns
  tasks.each do |num, task|
    normalized_task = "state=#{task['state']} #{task['title']}"
    match = true
    search_patterns.each do |pattern|
      match = false unless /#{pattern}/ix.match(normalized_task)
    end
    items[num] = task if match
  end
  items = items.sort_by do |num, task|
    prio = PRIO[task['state'] || 'default']
    [task['priority'] ? 0 : 1, prio.to_s, num]
  end
  items.each do |num, task|
    state = task['state'] || 'default'
    color = COLORS[state]
    display_state = colorize(STATES[state], color)
    title = task['title'].gsub(/@\w+/) { |tag| colorize(tag, :cyan) }
    puts "#{colorize(task['priority'] ? '*' : ' ', :red)}#{num.to_s.rjust(4, ' ')}: #{display_state} #{title}"
  end
end

def add_note(item, text)
  tasks = get_tasks
  check_item(tasks, item)
  tasks[item]['note'] ||= []
  tasks[item]['note'].push(text)
  tasks[item]['modified'] = Time.now.strftime(DATE_FORMAT)
  write_tasks(tasks)
  show(item)
end

def show(item)
  tasks = get_tasks
  check_item(tasks, item)
  tasks[item].each do |key, value|
    val = value.kind_of?(Array) ? "\n" + value.join("\n") : value
    puts "#{colorize(key.to_s.rjust(10, ' '), :cyan)}: #{val}"
  end
end

def check_item(tasks, item)
  unless tasks.has_key?(item)
    puts "#{colorize('ERROR:', :red)} #{item}: No such todo"
    exit
  end
end

def colorize(text, color)
  "\e[#{COLOR_CODES[color]}m#{text}\e[0m"
end

def read(arguments)
  action = arguments.first
  args = arguments[1..-1]

  case action
  when 'add'
    add(args.join(' ')) unless args.nil? || args.empty?
  when 'start'
    args.length == 1 ? change_state(args.first.to_i, 'started') : list(nil, ['state=started'])
  when 'done'
    args.length == 1 ? change_state(args.first.to_i, 'done') : list(nil, ['state=done'])
  when 'block'
    args.length == 1 ? change_state(args.first.to_i, 'blocked') : list(nil, ['state=blocked'])
  when 'prio'
    set_priority(args.first.to_i) if args.length == 1
  when 'append'
    append(args.first.to_i, args[1..-1].join(' ')) unless args.length < 1
  when 'replace'
    replace(args.first.to_i, args[1..-1].join(' ')) unless args.length < 1
  when 'del'
    delete(args.first.to_i) if args.length == 1
  when 'note'
    add_note(args.first.to_i, args[1..-1].join(' ')) unless args.length < 1
  when 'list'
    list(nil, args)
  when 'show'
    show(args.first.to_i) if args.length == 1
  when 'help'
    puts usage
  else
    list(nil, arguments)
  end
end

read(ARGV)
