#!/usr/bin/env ruby

# todo.rb - todo list manager on the command-line
# inspired by todo.txt using the jsonl format.
#
# Copyright (c) 2020-2021 Gabor Bata
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
require 'date'

class Todo
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
    'waiting' => '[@]',
    'default' => '[?]'
  }

  ORDER = {
    'new'     => 3,
    'done'    => 5,
    'started' => 2,
    'blocked' => 1,
    'waiting' => 4,
    'default' => 100
  }

  COLORS = {
    'new'     => :white,
    'done'    => :blue,
    'started' => :green,
    'blocked' => :yellow,
    'waiting' => :cyan,
    'default' => :magenta
  }

  DATE_FORMAT = '%Y-%m-%d'
  DUE_DATE_DAYS_SIMPLE = ['today', 'tomorrow']
  DUE_DATE_TAG_PATTERN = /(^| )due:([a-zA-Z0-9-]+)/
  CONTEXT_TAG_PATTERN = /(^| )[@+][\w-]+/
  PRIORITY_FLAG = '*'
  TODO_FILE = File.join(Dir.home, 'todo.jsonl')

  def execute(arguments)
    begin
      setup
      action = arguments.first
      args = arguments.drop(1)
      case action
      when 'add'
        raise action + ' command requires at least one parameter' if args.empty?
        add(args.join(' '))
      when 'start'
        args.length > 0 ? change_state(args.first.to_i, 'started', args.drop(1).join(' ')) : list(nil, [':started'])
      when 'done'
        args.length > 0 ? change_state(args.first.to_i, 'done', args.drop(1).join(' ')) : list(nil, [':done'])
      when 'block'
        args.length > 0 ? change_state(args.first.to_i, 'blocked', args.drop(1).join(' ')) : list(nil, [':blocked'])
      when 'wait'
        args.length > 0 ? change_state(args.first.to_i, 'waiting', args.drop(1).join(' ')) : list(nil, [':waiting'])
      when 'reset'
        args.length > 0 ? change_state(args.first.to_i, 'new', args.drop(1).join(' ')) : list(nil, [':new'])
      when 'prio'
        raise action + ' command requires at least one parameter' if args.length < 1
        set_priority(args.first.to_i, args.drop(1).join(' '))
      when 'due'
        raise action + ' command requires at least one parameter' if args.length < 1
        due_date(args.first.to_i, args.drop(1).join(' '))
      when 'append'
        raise action + ' command requires at least two parameters' if args.length < 2
        append(args.first.to_i, args.drop(1).join(' '))
      when 'rename'
        raise action + ' command requires at least two parameters' if args.length < 2
        rename(args.first.to_i, args.drop(1).join(' '))
      when 'del'
        raise action + ' command requires exactly one parameter' if args.length != 1
        delete(args.first.to_i)
      when 'note'
        raise action + ' command requires at least two parameters' if args.length < 2
        add_note(args.first.to_i, args.drop(1).join(' '))
      when 'delnote'
        raise action + ' command requires one or two parameters' if args.length < 1 || args.length > 2
        delete_note(args.first.to_i, args[1])
      when 'list'
        list(nil, args)
      when 'show'
        raise action + ' command requires exactly one parameter' if args.length != 1
        show(args.first.to_i)
      when 'help'
        raise action + ' command has no parameters' if args.length > 0
        puts usage
      when 'repl'
        raise action + ' command has no parameters' if args.length > 0
        start_repl
      when 'cleanup'
        raise action + ' command requires at least one parameter' if args.empty?
        cleanup(args)
      else
        list(nil, arguments)
      end
    rescue StandardError => error
      puts "#{colorize('ERROR:', :red)} #{error}"
    end
    self
  end

  private

  def usage
    <<~USAGE
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
      #{@queries.keys.each_with_index.map { |k, i| (i == 8 ? "\n" : '') + k }.join(', ')}

      Due dates can be also added via tags in task title: "due:YYYY-MM-DD"
      In addition to formatted dates, you can use date synonyms:
      "due:today", "due:tomorrow", and day names e.g. "due:monday" or "due:tue"

      Legend: #{STATES.select { |k, v| k != 'default' }.map { |k, v| "#{k} #{v}" }.join(', ') }, priority #{PRIORITY_FLAG}

      Todo file: #{TODO_FILE}
    USAGE
  end

  def setup
    @today = Date.today
    next_7_days = (0..6).map { |day| @today + day }
    @due_date_days = next_7_days.map { |day| day.strftime('%A').downcase }
    due_dates_for_queries = next_7_days.map { |day| day.strftime(DATE_FORMAT) }
    recent_date = (@today - 7).strftime(DATE_FORMAT)
    @queries = {
      ':active'    => lambda { |task| /(new|started|blocked|waiting)/.match(task[:state]) },
      ':done'      => lambda { |task| 'done' == task[:state] },
      ':blocked'   => lambda { |task| 'blocked' == task[:state] },
      ':waiting'   => lambda { |task| 'waiting' == task[:state] },
      ':started'   => lambda { |task| 'started' == task[:state] },
      ':new'       => lambda { |task| 'new' == task[:state] },
      ':all'       => lambda { |task| /\w+/.match(task[:state]) },
      ':priority'  => lambda { |task| task[:priority] },
      ':note'      => lambda { |task| task[:note] && !task[:note].empty? },
      ':today'     => lambda { |task| due_dates_for_queries[0] == task[:due] },
      ':tomorrow'  => lambda { |task| due_dates_for_queries[1] == task[:due] },
      ':next7days' => lambda { |task| /(#{due_dates_for_queries.join('|')})/.match(task[:due]) },
      ':overdue'   => lambda { |task| task[:due] && task[:due] < due_dates_for_queries[0] },
      ':due'       => lambda { |task| task[:due] },
      ':recent'    => lambda { |task| recent_date <= task[:modified] }
    }
  end

  def load_tasks(item_to_check = nil)
    count = 0
    tasks = {}
    if File.exist?(TODO_FILE)
      File.open(TODO_FILE, 'r:UTF-8') do |file|
        file.each_line do |line|
          next if line.strip == ''
          count += 1
          tasks[count] = JSON.parse(line.chomp, :symbolize_names => true)
        end
      end
    end
    raise "#{item_to_check}: No such todo" if item_to_check && !tasks.has_key?(item_to_check)
    tasks
  end

  def write_tasks(tasks)
    File.open(TODO_FILE, 'w:UTF-8') do |file|
      tasks.keys.sort.each { |key| file.write(JSON.generate(tasks[key]) + "\n") }
    end
  end

  def postprocess_tags(task)
    match_data = task[:title].match(DUE_DATE_TAG_PATTERN)
    if match_data
      task[:title] = task[:title].gsub(DUE_DATE_TAG_PATTERN, '')
      task[:due] = convert_due_date(match_data[2])
    end
    raise 'title must not be empty' if task[:title].empty?
  end

  def add(text)
    task = { state: 'new', title: text, modified: @today.strftime(DATE_FORMAT) }
    postprocess_tags(task)
    File.open(TODO_FILE, 'a:UTF-8') { |file| file.write(JSON.generate(task) + "\n") }
    list
  end

  def update_task(item, post_action, update_function)
    tasks = load_tasks(item)
    update_function.call(tasks[item])
    tasks[item][:modified] = @today.strftime(DATE_FORMAT)
    write_tasks(tasks)
    case post_action
    when :show then show(item, tasks)
    when :list then list(tasks)
    end
  end

  def append(item, text)
    update_task(item, :list, lambda do |task|
      task[:title] = [task[:title], text].join(' ')
      postprocess_tags(task)
    end)
  end

  def rename(item, text)
    update_task(item, :list, lambda do |task|
      task[:title] = text
      postprocess_tags(task)
    end)
  end

  def delete(item)
    tasks = load_tasks(item)
    tasks.delete(item)
    write_tasks(tasks)
    list
  end

  def change_state(item, state, note = nil)
    update_task(item, :list, lambda do |task|
      task[:state] = state
      if !note.nil? && !note.empty?
        task[:note] ||= []
        task[:note].push(note)
      end
    end)
  end

  def set_priority(item, note = nil)
    update_task(item, :list, lambda do |task|
      task[:priority] = !task[:priority]
      task.delete(:priority) if !task[:priority]
      if !note.nil? && !note.empty?
        task[:note] ||= []
        task[:note].push(note)
      end
    end)
  end

  def due_date(item, date = '')
    update_task(item, :list, lambda do |task|
      task[:due] = convert_due_date(date)
      task.delete(:due) if task[:due].nil?
    end)
  end

  def list(tasks = nil, patterns = nil)
    tasks ||= load_tasks
    task_indent = [tasks.keys.max.to_s.size, 4].max
    patterns ||= []
    patterns += [':active'] if (patterns & [':active', ':done', ':blocked', ':started', ':new', ':all', ':waiting']).empty?
    items = filter_tasks(tasks, patterns).sort_by do |num, task|
      [
        task[:priority] && task[:state] != 'done' ? 0 : 1,
        ORDER[task[:state] || 'default'] || ORDER['default'],
        task[:state] != 'done' ? task[:due] || 'n/a' : task[:modified],
        num
      ]
    end
    items.each do |num, task|
      state = task[:state] || 'default'
      display_state = colorize(STATES[state], COLORS[state])
      title = task[:title].gsub(CONTEXT_TAG_PATTERN) do |tag|
        (tag.start_with?(' ') ? ' ' : '') + colorize(tag.strip, :cyan)
      end
      priority_flag = task[:priority] && state != 'done' ? colorize(PRIORITY_FLAG, :red) : ' '
      due_date = ''
      if task[:due] && state != 'done'
        date_diff = (Date.strptime(task[:due], DATE_FORMAT) - @today).to_i
        if date_diff < 0
          due_date = colorize("(#{date_diff.abs}d overdue)", :red)
        elsif date_diff == 0 || date_diff == 1
          due_date = colorize("(#{DUE_DATE_DAYS_SIMPLE[date_diff]})", :yellow)
        else
          due_date = colorize("(#{@due_date_days[date_diff] || task[:due]})", :magenta) if date_diff > 1
        end
        due_date = ' ' + due_date
      end
      puts "#{num.to_s.rjust(task_indent)}:#{priority_flag}#{display_state} #{title}#{due_date}"
    end
    puts 'No todos found' if items.empty?
  end

  def add_note(item, text)
    update_task(item, :show, lambda do |task|
      task[:note] ||= []
      task[:note].push(text)
    end)
  end

  def delete_note(item, num = nil)
    update_task(item, :show, lambda do |task|
      if num.to_s.empty?
        task.delete(:note)
      else
        raise "#{num.to_i}: Note does not exist" if num.to_i <= 0 || task[:note].to_a.size < num.to_i
        task[:note].delete_at(num.to_i - 1)
        task.delete(:note) if task[:note].empty?
      end
    end)
  end

  def show(item, tasks = nil)
    tasks ||= load_tasks(item)
    tasks[item].each do |k, v|
      v = "\n" + v.each_with_index.
        map { |n, i| v.size > 1 ? "#{(i + 1).to_s.rjust(v.size.to_s.size)}: #{n}" : n }.
        join("\n") if v.is_a?(Array)
      puts "#{colorize(k.to_s.rjust(10) + ':', :cyan)} #{v}"
    end
  end

  def start_repl
    command = ''
    while !['exit', 'quit'].include?(command)
      if ['clear', 'cls'].include?(command)
        print "\e[H\e[2J"
      else
        execute(command == 'repl' ? [] : command.split(/\s+/))
      end
      print "\ntodo> "
      command = STDIN.gets.chomp.strip
    end
  end

  def cleanup(patterns)
    tasks = load_tasks
    patterns = [':done'] + patterns.to_a
    items = filter_tasks(tasks, patterns)
    items.each_key { |num| tasks.delete(num) }
    write_tasks(tasks)
    puts "Deleted #{items.size} todo(s)"
  end

  def filter_tasks(tasks, patterns)
    patterns = patterns.uniq
    tasks.select do |num, task|
      patterns.all? do |pattern|
        @queries[pattern] ? @queries[pattern].call(task) : /#{pattern}/ix.match(task[:title])
      end
    end
  end

  def colorize(text, color)
    "\e[#{COLOR_CODES[color] || 37}m#{text}\e[0m"
  end

  def convert_due_date(date)
    day_index = @due_date_days.index(date.to_s.downcase) ||
      DUE_DATE_DAYS_SIMPLE.index(date.to_s.downcase) ||
      @due_date_days.map { |day| day[0..2] }.index(date.to_s.downcase)
    return (@today + day_index).strftime(DATE_FORMAT) if day_index
    date.nil? || date.empty? ? nil : Date.strptime(date, DATE_FORMAT).strftime(DATE_FORMAT)
  end
end

Todo.new.execute(ARGV)
