#!/usr/bin/env ruby

# todo.rb - todo list manager inspired by todo.txt using the jsonl format.
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
    'default' => '[?]'
  }

  ORDER = {
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

  DATE_FORMAT = '%Y-%m-%d'
  DUE_DATE_DAYS_SIMPLE = ['today', 'tomorrow']
  DUE_DATE_TAG_PATTERN = /(^| )due:([a-zA-Z0-9-]+)/
  CONTEXT_TAG_PATTERN = /(^| )[@+][\w-]+/
  PRIORITY_FLAG = '*'
  TODO_FILE = "#{ENV['HOME']}/todo.jsonl"

  def execute(arguments)
    begin
      setup
      action = arguments.first
      args = arguments[1..-1] || []
      case action
      when 'add'
        raise action + ' command requires at least one parameter' if args.nil? || args.empty?
        add(args.join(' '))
      when 'start'
        args.length > 0 ? change_state(args.first.to_i, 'started', (args[1..-1] || []).join(' ')) : list(nil, [':started'])
      when 'done'
        args.length > 0 ? change_state(args.first.to_i, 'done', (args[1..-1] || []).join(' ')) : list(nil, [':done'])
      when 'block'
        args.length > 0 ? change_state(args.first.to_i, 'blocked', (args[1..-1] || []).join(' ')) : list(nil, [':blocked'])
      when 'reset'
        args.length > 0 ? change_state(args.first.to_i, 'new', (args[1..-1] || []).join(' ')) : list(nil, [':new'])
      when 'prio'
        raise action + ' command requires at least one parameter' if args.length < 1
        set_priority(args.first.to_i, (args[1..-1] || []).join(' '))
      when 'due'
        raise action + ' command requires at least one parameter' if args.length < 1
        due_date(args.first.to_i, (args[1..-1] || []).join(' '))
      when 'append'
        raise action + ' command requires at least two parameters' if args.length < 2
        append(args.first.to_i, args[1..-1].join(' '))
      when 'rename'
        raise action + ' command requires at least two parameters' if args.length < 2
        rename(args.first.to_i, args[1..-1].join(' '))
      when 'del'
        raise action + ' command requires exactly one parameter' if args.length != 1
        delete(args.first.to_i)
      when 'note'
        raise action + ' command requires at least two parameters' if args.length < 2
        add_note(args.first.to_i, args[1..-1].join(' '))
      when 'delnote'
        raise action + ' command requires exactly one parameter' if args.length != 1
        delete_note(args.first.to_i)
      when 'list'
        list(nil, args)
      when 'show'
        raise action + ' command requires exactly one parameter' if args.length != 1
        show(args.first.to_i)
      when 'help'
        puts usage
      when 'repl'
        start_repl
      else
        list(nil, arguments)
      end
    rescue => error
      puts "#{colorize('ERROR:', :red)} #{error}"
    end
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
      * help                           this help screen

      With list command the following pre-defined regex patterns can be also used:
      #{@queries.keys.join(', ')}

      Due dates can be also added via tags in task title: "due:YYYY-MM-DD"

      Legend:
      #{STATES.select { |k, v| k != 'default' }.map { |k, v| "#{k} #{v}" }.join(', ') }, priority #{PRIORITY_FLAG}

      Todo file: #{TODO_FILE}
    USAGE
  end

  def setup
    @today = Time.now
    next_7_days = (0..6).map do |day| (@today.to_date + day) end
    @due_date_days = next_7_days.map do |day| day.strftime('%A').downcase end
    due_dates_for_queries = next_7_days.map do |day| day.strftime(DATE_FORMAT) end

    @queries = {
      ':active'    => 'state=(new|started|blocked)',
      ':done'      => 'state=done',
      ':blocked'   => 'state=blocked',
      ':started'   => 'state=started',
      ':new'       => 'state=new',
      ':all'       => 'state=\w+',
      ':today'     => "due=#{due_dates_for_queries[0]}",
      ':tomorrow'  => "due=#{due_dates_for_queries[1]}",
      ':next7days' => "due=(#{due_dates_for_queries.join('|')})"
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
    if item_to_check && !tasks.has_key?(item_to_check)
      raise "#{item_to_check}: No such todo"
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

  def postprocess_tags(task)
    match_data = task[:title].match(DUE_DATE_TAG_PATTERN)
    if match_data
      task[:title] = task[:title].gsub(DUE_DATE_TAG_PATTERN, '')
      task[:due] = convert_due_date(match_data[2])
    end
    raise 'title must not be empty' if task[:title].empty?
  end

  def add(text)
    task = {
      state: 'new',
      title: text,
      modified: @today.strftime(DATE_FORMAT)
    }
    postprocess_tags(task)
    File.open(TODO_FILE, 'a:UTF-8') do |file|
      file.write(JSON.generate(task) + "\n")
    end
    list
  end

  def append(item, text = '')
    tasks = load_tasks(item)
    tasks[item][:title] = [tasks[item][:title], text].join(' ')
    tasks[item][:modified] = @today.strftime(DATE_FORMAT)
    postprocess_tags(tasks[item])
    write_tasks(tasks)
    list(tasks)
  end

  def rename(item, text)
    tasks = load_tasks(item)
    tasks[item][:title] = text
    tasks[item][:modified] = @today.strftime(DATE_FORMAT)
    postprocess_tags(tasks[item])
    write_tasks(tasks)
    list(tasks)
  end

  def delete(item)
    tasks = load_tasks(item)
    tasks.delete(item)
    write_tasks(tasks)
    list
  end

  def change_state(item, state, note = nil)
    tasks = load_tasks(item)
    tasks[item][:state] = state
    tasks[item][:modified] = @today.strftime(DATE_FORMAT)
    if !note.nil? && !note.empty?
      tasks[item][:note] ||= []
      tasks[item][:note].push(note)
    end
    write_tasks(tasks)
    list(tasks)
  end

  def set_priority(item, note = nil)
    tasks = load_tasks(item)
    tasks[item][:priority] = !tasks[item][:priority]
    tasks[item].delete(:priority) if !tasks[item][:priority]
    tasks[item][:modified] = @today.strftime(DATE_FORMAT)
    if !note.nil? && !note.empty?
      tasks[item][:note] ||= []
      tasks[item][:note].push(note)
    end
    write_tasks(tasks)
    list(tasks)
  end

  def due_date(item, date = '')
    tasks = load_tasks(item)
    tasks[item][:due] = convert_due_date(date)
    tasks[item].delete(:due) if tasks[item][:due].nil?
    tasks[item][:modified] = @today.strftime(DATE_FORMAT)
    write_tasks(tasks)
    list(tasks)
  end

  def list(tasks = nil, patterns = nil)
    items = {}
    tasks = tasks || load_tasks
    task_indent = [tasks.keys.max.to_s.size, 4].max
    patterns = patterns.nil? || patterns.empty? ? [@queries[':active']] : patterns
    tasks.each do |num, task|
      normalized_task = "state=#{task[:state]} due=#{task[:due]} #{task[:title]}"
      match = true
      patterns.each do |pattern|
        match = false unless /#{@queries[pattern] || pattern}/ix.match(normalized_task)
      end
      items[num] = task if match
    end
    items = items.sort_by do |num, task|
      [task[:priority] && task[:state] != 'done' ? 0 : 1, ORDER[task[:state] || 'default'], task[:due] || 'n/a', num]
    end
    items.each do |num, task|
      state = task[:state] || 'default'
      color = COLORS[state]
      display_state = colorize(STATES[state], color)
      title = task[:title].gsub(CONTEXT_TAG_PATTERN) do |tag|
        (tag.start_with?(' ') ? ' ' : '') + colorize(tag.strip, :cyan)
      end
      priority_flag = task[:priority] ? colorize(PRIORITY_FLAG, :red) : ' '
      due_date = ''
      if task[:due] && state != 'done'
        date_diff = (Date.parse(task[:due]) - @today.to_date).to_i
        if date_diff < 0
          due_date = colorize("(#{date_diff.abs}d overdue)", :red)
        elsif date_diff == 0 || date_diff == 1
          due_date = colorize("(#{DUE_DATE_DAYS_SIMPLE[date_diff]})", :yellow)
        else
          due_date = colorize("(#{@due_date_days[date_diff] || task[:due]})", :magenta) if date_diff > 1
        end
        due_date = ' ' + due_date
      end
      puts "#{num.to_s.rjust(task_indent, ' ')}:#{priority_flag}#{display_state} #{title}#{due_date}"
    end
    puts 'No todos found' if items.empty?
  end

  def add_note(item, text)
    tasks = load_tasks(item)
    tasks[item][:note] ||= []
    tasks[item][:note].push(text)
    tasks[item][:modified] = @today.strftime(DATE_FORMAT)
    write_tasks(tasks)
    show(item)
  end

  def delete_note(item)
    tasks = load_tasks(item)
    tasks[item].delete(:note)
    tasks[item][:modified] = @today.strftime(DATE_FORMAT)
    write_tasks(tasks)
    show(item)
  end

  def show(item)
    tasks = load_tasks(item)
    tasks[item].each do |key, value|
      val = value.kind_of?(Array) ? "\n" + value.join("\n") : value
      puts "#{colorize(key.to_s.rjust(10, ' ') + ':', :cyan)} #{val}"
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
      command = STDIN.gets.chomp
    end
  end

  def colorize(text, color)
    "\e[#{COLOR_CODES[color]}m#{text}\e[0m"
  end

  def convert_due_date(date = '')
    due = nil
    day_index = @due_date_days.index(date.to_s.downcase) ||
      DUE_DATE_DAYS_SIMPLE.index(date.to_s.downcase) ||
      @due_date_days.map do |day| day[0..2] end.index(date.to_s.downcase)
    if day_index
      due = (@today.to_date + day_index).strftime(DATE_FORMAT)
    else
      due = date.nil? || date.empty? ? nil : Date.parse(date).strftime(DATE_FORMAT)
    end
    return due
  end

end

Todo.new.execute(ARGV)
