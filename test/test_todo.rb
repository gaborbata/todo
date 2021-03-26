require 'test/unit'
require 'coverage'
require 'stringio'

class Dir
  def self.home
    Dir.pwd
  end
end

class TestTodo < Test::Unit::TestCase
  class << self
    def startup
      Coverage.start if ENV['COVERAGE']
    end

    def shutdown
      if ENV['COVERAGE']
        coverage = Coverage.result.find { |name, result| name.end_with?('bin/todo.rb') }
        coverage = coverage ? coverage[1] : []
        relevant = coverage.select { |line| !line.nil? }.size
        covered = coverage.select { |line| !line.nil? && line > 0 }.size
        printf("\nCoverage: %.2f%% (lines: %d total, %d relevant, %d covered, %d missed)\n",
          covered.to_f / [relevant.to_f, 1.0].max * 100.0, coverage.size, relevant, covered, relevant - covered)
      end
    end
  end

  def setup
    @original_stdout = $stdout
    $stdout = StringIO.new
    require_relative '../bin/todo.rb'
    @todo_file = Todo::TODO_FILE
    File.delete(@todo_file) if File.exist?(@todo_file)
    @todo = Todo.new
    @todo.execute ['add', 'Buy Milk']
  end

  def cleanup
    $stdout = @original_stdout
    File.delete(@todo_file) if File.exist?(@todo_file)
  end

  def test_add_new
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk", $stdout.string.split("\n").last)
  end

  def test_start
    $stdout = StringIO.new
    @todo.execute ['start', '1']
    assert_match(
      /{"state":"started","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[32m[>]\e[0m Buy Milk\n", $stdout.string)
  end

  def test_reset
    @todo.execute ['start', '1']
    $stdout = StringIO.new
    @todo.execute ['reset', '1']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk\n", $stdout.string)
  end

  def test_start_not_existing_todo
    $stdout = StringIO.new
    @todo.execute ['start', '2']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("\e[31mERROR:\e[0m 2: No such todo\n", $stdout.string)
  end

  def test_done
    $stdout = StringIO.new
    @todo.execute ['done', '1']
    assert_match(
      /{"state":"done","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("No todos found\n", $stdout.string)
  end

  def test_block
    $stdout = StringIO.new
    @todo.execute ['block', '1']
    assert_match(
      /{"state":"blocked","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[33m[!]\e[0m Buy Milk\n", $stdout.string)
  end

  def test_priority
    $stdout = StringIO.new
    @todo.execute ['prio', '1']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}","priority":true}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1:\e[31m*\e[0m\e[37m[ ]\e[0m Buy Milk\n", $stdout.string)
  end

  def test_priority_with_note
    $stdout = StringIO.new
    @todo.execute ['prio', '1', 'very important']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}","priority":true,"note":\["very important"\]}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1:\e[31m*\e[0m\e[37m[ ]\e[0m Buy Milk\n", $stdout.string)
  end

  def test_due_date
    $stdout = StringIO.new
    @todo.execute ['due', '1', Time.now.strftime(Todo::DATE_FORMAT)]
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}","due":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk \e[33m(today)\e[0m\n", $stdout.string)
  end

  def test_unset_due_date
    @todo.execute ['due', '1', Time.now.strftime(Todo::DATE_FORMAT)]
    $stdout = StringIO.new
    @todo.execute ['due', '1']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk\n", $stdout.string)
  end

  def test_due_date_tag
    @todo.execute ['del', '1']
    $stdout = StringIO.new
    @todo.execute ['add', "Buy Milk ASAP due:#{Time.now.strftime(Todo::DATE_FORMAT)}"]
    assert_match(
      /{"state":"new","title":"Buy Milk ASAP","modified":"\d{4}-\d{2}-\d{2}","due":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk ASAP \e[33m(today)\e[0m\n", $stdout.string)
  end

  def test_due_date_tag_with_day_name
    @todo.execute ['del', '1']
    $stdout = StringIO.new
    @todo.execute ['add', "Buy Milk ASAP due:Friday"]
    assert_match(
      /{"state":"new","title":"Buy Milk ASAP","modified":"\d{4}-\d{2}-\d{2}","due":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
  end

  def test_due_date_tag_with_short_day_name
    @todo.execute ['del', '1']
    $stdout = StringIO.new
    @todo.execute ['add', "Buy Milk ASAP due:wed"]
    assert_match(
      /{"state":"new","title":"Buy Milk ASAP","modified":"\d{4}-\d{2}-\d{2}","due":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
  end

  def test_due_date_tag_with_simple_day_name
    @todo.execute ['del', '1']
    $stdout = StringIO.new
    @todo.execute ['add', "Buy Milk ASAP due:tomorrow"]
    assert_match(
      /{"state":"new","title":"Buy Milk ASAP","modified":"\d{4}-\d{2}-\d{2}","due":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk ASAP \e[33m(tomorrow)\e[0m\n", $stdout.string)
  end

  def test_due_date_tag_in_rename
    $stdout = StringIO.new
    @todo.execute ['rename', '1', "Buy Milk ASAP due:#{Time.now.strftime(Todo::DATE_FORMAT)}"]
    assert_match(
      /{"state":"new","title":"Buy Milk ASAP","modified":"\d{4}-\d{2}-\d{2}","due":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk ASAP \e[33m(today)\e[0m\n", $stdout.string)
  end

  def test_toggle_priority
    @todo.execute ['prio', '1']
    $stdout = StringIO.new
    @todo.execute ['prio', '1']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk\n", $stdout.string)
  end

  def test_append
    $stdout = StringIO.new
    @todo.execute ['append', '1', 'ASAP']
    assert_match(
      /{"state":"new","title":"Buy Milk ASAP","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk ASAP\n", $stdout.string)
  end

  def test_rename_todo
    $stdout = StringIO.new
    @todo.execute ['rename', '1', 'Buy Bread']
    assert_match(
      /{"state":"new","title":"Buy Bread","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Bread\n", $stdout.string)
  end

  def test_delete_todo
    $stdout = StringIO.new
    @todo.execute ['del', '1']
    assert_equal(
      '',
      File.read(@todo_file)
    )
    assert_equal("No todos found\n", $stdout.string)
  end

  def test_delete_non_exiting_todo
    $stdout = StringIO.new
    @todo.execute ['del', '42']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("\e[31mERROR:\e[0m 42: No such todo\n", $stdout.string)
  end

  def test_delete_todo_should_reorganize_numbers
    @todo.execute ['add', 'Buy Rice']
    $stdout = StringIO.new
    @todo.execute ['del', '1']
    assert_match(
      /{"state":"new","title":"Buy Rice","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("   1: \e[37m[ ]\e[0m Buy Rice\n", $stdout.string)
  end

  def test_add_note
    $stdout = StringIO.new
    @todo.execute ['note', '1', 'test']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}","note":\["test"\]}\r?\n/,
      File.read(@todo_file)
    )
    assert_match(
      /\e\[36m {5}state:\e\[0m new\n\e\[36m {5}title:\e\[0m Buy Milk\n\e\[36m  modified:\e\[0m \d{4}-\d{2}-\d{2}\n\e\[36m {6}note:\e\[0m \ntest\n/,
      $stdout.string
    )
  end

  def test_delete_notes
    @todo.execute ['note', '1', 'a note']
    $stdout = StringIO.new
    @todo.execute ['delnote', '1']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_match(
      /\e\[36m {5}state:\e\[0m new\n\e\[36m {5}title:\e\[0m Buy Milk\n\e\[36m  modified:\e\[0m \d{4}-\d{2}-\d{2}\n/,
      $stdout.string
    )
  end

  def test_delete_specific_note
    @todo.execute ['note', '1', 'first note']
    @todo.execute ['note', '1', 'second note']
    $stdout = StringIO.new
    @todo.execute ['delnote', '1', '2']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}","note":\["first note"\]}\r?\n/,
      File.read(@todo_file)
    )
    assert_match(
      /\e\[36m {5}state:\e\[0m new\n\e\[36m {5}title:\e\[0m Buy Milk\n\e\[36m  modified:\e\[0m \d{4}-\d{2}-\d{2}\n\e\[36m {6}note:\e\[0m \nfirst note\n/,
      $stdout.string
    )
  end

  def test_delete_last_note
    @todo.execute ['note', '1', 'first note']
    $stdout = StringIO.new
    @todo.execute ['delnote', '1', '1']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_match(
      /\e\[36m {5}state:\e\[0m new\n\e\[36m {5}title:\e\[0m Buy Milk\n\e\[36m  modified:\e\[0m \d{4}-\d{2}-\d{2}\n/,
      $stdout.string
    )
  end

  def test_delete_non_existing_note
    $stdout = StringIO.new
    @todo.execute ['delnote', '1', '1']
    assert_equal("\e[31mERROR:\e[0m 1: Note does not exist\n", $stdout.string)
  end

  def test_change_state_with_note
    @todo.execute ['block', '1', 'note']
    assert_match(
      /{"state":"blocked","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}","note":\["note"\]}\r?\n/,
      File.read(@todo_file)
    )
  end

  def test_without_parameters
    $stdout = StringIO.new
    @todo.execute []
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk\n", $stdout.string)
  end

  def test_show_todo
    $stdout = StringIO.new
    @todo.execute ['show', '1']
    assert_match(
      /\e\[36m {5}state:\e\[0m new\n\e\[36m {5}title:\e\[0m Buy Milk\n\e\[36m  modified:\e\[0m \d{4}-\d{2}-\d{2}\n/,
      $stdout.string
    )
  end

  def test_list_by_context_tag
    @todo.execute ['add', 'Buy Bread @breakfast']
    $stdout = StringIO.new
    @todo.execute ['list', '@breakfast']
    assert_equal("   2: \e[37m[ ]\e[0m Buy Bread \e[36m@breakfast\e[0m\n", $stdout.string)
  end

  def test_list_by_project_tag
    @todo.execute ['add', 'Buy Bread +breakfast']
    $stdout = StringIO.new
    @todo.execute ['list', '\\+breakfast']
    assert_equal("   2: \e[37m[ ]\e[0m Buy Bread \e[36m+breakfast\e[0m\n", $stdout.string)
  end

  def test_list_all_by_pre_defined_query
    @todo.execute ['done', '1']
    $stdout = StringIO.new
    @todo.execute ['list', ':all']
    assert_equal("   1: \e[34m[x]\e[0m Buy Milk\n", $stdout.string)
  end

  def test_list_active_tasks_by_default
    @todo.execute ['append', '1', '@breakfast']
    @todo.execute ['done', '1']
    @todo.execute ['add', 'Buy Bread @breakfast']
    $stdout = StringIO.new
    @todo.execute ['list', '@breakfast']
    assert_equal("   2: \e[37m[ ]\e[0m Buy Bread \e[36m@breakfast\e[0m\n", $stdout.string)
  end

  def test_list_recently_updated_tasks
    $stdout = StringIO.new
    @todo.execute ['list', ':recent']
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk\n", $stdout.string)
  end

  def test_list_non_matching_multiple_regex
    $stdout = StringIO.new
    @todo.execute ['list', 'milk', 'bread']
    assert_equal("No todos found\n", $stdout.string)
  end

  def test_list_by_due_date
    @todo.execute ['due', '1', Time.now.strftime(Todo::DATE_FORMAT)]
    @todo.execute ['add', 'Buy Bread @unplanned']
    $stdout = StringIO.new
    @todo.execute ['list', ':today']
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk \e[33m(today)\e[0m\n", $stdout.string)
  end

  def test_list_by_next_7_days
    @todo.execute ['due', '1', 'tomorrow']
    @todo.execute ['add', 'Buy Bread @unplanned']
    $stdout = StringIO.new
    @todo.execute ['list', ':next7days']
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk \e[33m(tomorrow)\e[0m\n", $stdout.string)
  end

  def test_list_overdue_tasks
    @todo.execute ['add', "Opean Tutankhamen's burial chamber due:1923-02-16"]
    $stdout = StringIO.new
    @todo.execute ['list', ':overdue']
    assert_match(/   2: \e\[37m\[ \]\e\[0m Opean Tutankhamen's burial chamber \e\[31m\(\d+d overdue\)\e\[0m\n/, $stdout.string)
  end

  def test_list_tasks_with_due_dates
    @todo.execute ['due', '1', 'tomorrow']
    @todo.execute ['add', 'Buy Bread @unplanned']
    $stdout = StringIO.new
    @todo.execute ['list', ':due']
    assert_equal("   1: \e[37m[ ]\e[0m Buy Milk \e[33m(tomorrow)\e[0m\n", $stdout.string)
  end

  def test_list_tasks_with_notes
    @todo.execute ['add', 'Buy Bread']
    @todo.execute ['note', '2', 'A note']
    $stdout = StringIO.new
    @todo.execute ['list', ':note']
    assert_equal("   2: \e[37m[ ]\e[0m Buy Bread\n", $stdout.string)
  end

  def test_list_priority_tasks
    @todo.execute ['add', 'Very important task']
    @todo.execute ['prio', '2']
    $stdout = StringIO.new
    @todo.execute ['list', ':priority']
    assert_equal("   2:\e[31m*\e[0m\e[37m[ ]\e[0m Very important task\n", $stdout.string)
  end

  def test_invalid_date
    $stdout = StringIO.new
    @todo.execute ['due', '1', 'kedd']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("\e[31mERROR:\e[0m invalid date\n", $stdout.string)
  end

  def test_cleanup_with_non_matching_todos
    @todo.execute ['rename', '1', 'Buy Bread @breakfast']
    $stdout = StringIO.new
    @todo.execute ['cleanup', '@breakfast']
    assert_match(
      /{"state":"new","title":"Buy Bread @breakfast","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("Deleted 0 todo(s)\n", $stdout.string)
  end

  def test_cleanup
    @todo.execute ['rename', '1', 'Buy Bread @breakfast']
    @todo.execute ['add', 'Buy Eggs @breakfast']
    @todo.execute ['done', '1']
    $stdout = StringIO.new
    @todo.execute ['cleanup', '@breakfast']
    assert_match(
      /{"state":"new","title":"Buy Eggs @breakfast","modified":"\d{4}-\d{2}-\d{2}"}\r?\n/,
      File.read(@todo_file)
    )
    assert_equal("Deleted 1 todo(s)\n", $stdout.string)
  end
end
