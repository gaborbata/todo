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
  'new'     => '[ ]',
  'done'    => '[x]',
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

QUERIES = {
  ':active'  => 'state=(new|started|blocked)',
  ':done'    => 'state=done',
  ':blocked' => 'state=blocked',
  ':started' => 'state=started',
  ':new'     => 'state=new',
  ':all'     => 'state=\w+'
}

PRIORITY_FLAG = '*'

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
    * rename <tasknumber> <text>     rename task
    * del <tasknumber>               delete task
    * note <tasknumber> <text>       add note to task
    * delnote <tasknumber> <text>    delete all notes from task

    * list <regex> [regex...]        list tasks (only active tasks by default)
    * show <tasknumber>              show all task details
    * help                           this help screen

    With list command the following pre-defined regex patterns can be also used:
    #{QUERIES.keys.join(', ')}

    Legend:
    #{STATES.select { |k, v| k != 'default' }.map { |k, v| "#{k} #{v}" }.join(', ') }, priority #{PRIORITY_FLAG}
   USAGE
end

def get_tasks(item_to_check = nil)
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
  if item_to_check && !tasks.has_key?(item_to_check)
    puts "#{colorize('ERROR:', :red)} #{item_to_check}: No such todo"
    exit
  end
  tasks
end

def write_tasks(tasks)
  File.open(TODO_FILE, 'w:UTF-8') do |file|
    tasks.keys.sort.each do |key|
      file.write(JSON.generate(tasks[key]) + "\n")
    end
  end
end

def add(text)
  task = {
    'state' => 'new',
    'title' => text,
    'modified' => Time.now.strftime(DATE_FORMAT)
  }
  File.open(TODO_FILE, 'a:UTF-8') do |file|
    file.write(JSON.generate(task) + "\n")
  end
  list
end

def append(item, text = '')
  tasks = get_tasks(item)
  tasks[item]['title'] = [tasks[item]['title'], text].join(' ')
  tasks[item]['modified'] = Time.now.strftime(DATE_FORMAT)
  write_tasks(tasks)
  list(tasks)
end

def rename(item, text)
  tasks = get_tasks(item)
  tasks[item]['title'] = text
  tasks[item]['modified'] = Time.now.strftime(DATE_FORMAT)
  write_tasks(tasks)
  list(tasks)
end

def delete(item)
  tasks = get_tasks(item)
  tasks.delete(item)
  write_tasks(tasks)
  list
end

def change_state(item, state)
  tasks = get_tasks(item)
  tasks[item]['state'] = state
  tasks[item]['modified'] = Time.now.strftime(DATE_FORMAT)
  write_tasks(tasks)
  list(tasks)
end

def set_priority(item)
  tasks = get_tasks(item)
  tasks[item]['priority'] = !tasks[item]['priority']
  tasks[item]['modified'] = Time.now.strftime(DATE_FORMAT)
  write_tasks(tasks)
  list(tasks)
end

def list(tasks_map = nil, patterns = nil)
  items = {}
  tasks = tasks_map || get_tasks
  search_patterns = patterns.nil? || patterns.empty? ? [QUERIES[':active']] : patterns
  tasks.each do |num, task|
    normalized_task = "state=#{task['state']} #{task['title']}"
    match = true
    search_patterns.each do |pattern|
      match = false unless /#{QUERIES[pattern] || pattern}/ix.match(normalized_task)
    end
    items[num] = task if match
  end
  items = items.sort_by do |num, task|
    [task['priority'] ? 0 : 1, PRIO[task['state'] || 'default'], num]
  end
  items.each do |num, task|
    state = task['state'] || 'default'
    color = COLORS[state]
    display_state = colorize(STATES[state], color)
    title = task['title'].gsub(/@\w+/) { |tag| colorize(tag, :cyan) }
    priority_flag = task['priority'] ? colorize(PRIORITY_FLAG, :red) : ' '
    puts "#{num.to_s.rjust(4, ' ')}:#{priority_flag}#{display_state} #{title}"
  end
end

def add_note(item, text)
  tasks = get_tasks(item)
  tasks[item]['note'] ||= []
  tasks[item]['note'].push(text)
  tasks[item]['modified'] = Time.now.strftime(DATE_FORMAT)
  write_tasks(tasks)
  show(item)
end

def delete_note(item)
  tasks = get_tasks(item)
  tasks[item]['note'] = []
  tasks[item]['modified'] = Time.now.strftime(DATE_FORMAT)
  write_tasks(tasks)
  show(item)
end

def show(item)
  tasks = get_tasks(item)
  tasks[item].each do |key, value|
    val = value.kind_of?(Array) ? "\n" + value.join("\n") : value
    puts "#{colorize(key.to_s.rjust(10, ' '), :cyan)}: #{val}"
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
    args.length == 1 ? change_state(args.first.to_i, 'started') : list(nil, [':started'])
  when 'done'
    args.length == 1 ? change_state(args.first.to_i, 'done') : list(nil, [':done'])
  when 'block'
    args.length == 1 ? change_state(args.first.to_i, 'blocked') : list(nil, [':blocked'])
  when 'prio'
    set_priority(args.first.to_i) if args.length == 1
  when 'append'
    append(args.first.to_i, args[1..-1].join(' ')) unless args.length < 1
  when 'rename'
    rename(args.first.to_i, args[1..-1].join(' ')) unless args.length < 1
  when 'del'
    delete(args.first.to_i) if args.length == 1
  when 'note'
    add_note(args.first.to_i, args[1..-1].join(' ')) unless args.length < 1
  when 'delnote'
    delete_note(args.first.to_i) if args.length == 1
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
