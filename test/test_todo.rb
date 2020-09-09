require 'test/unit'

class TestTodo < Test::Unit::TestCase

  def setup
    ENV['HOME'] = Dir.pwd
    require_relative '../bin/todo.rb'
    read ['add', 'Buy Milk']
  end

  def teardown
    todo_file = "#{Dir.pwd}/todo.jsonl"
    File.delete(todo_file) if File.exist?(todo_file)
  end

  def test_add_new
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_start
    read ['start', '1']
    assert_match(
      /{"state":"started","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_start_not_existing_todo
    read ['start', '2']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_done
    read ['done', '1']
    assert_match(
      /{"state":"done","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_block
    read ['block', '1']
    assert_match(
      /{"state":"blocked","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}"}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_priority
    read ['prio', '1']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}","priority":true}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_toggle_priority
    read ['prio', '1']
    read ['prio', '1']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}","priority":false}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_append
    read ['append', '1', 'ASAP']
    assert_match(
      /{"state":"new","title":"Buy Milk ASAP","modified":"\d{4}-\d{2}-\d{2}"}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_rename_todo
    read ['rename', '1', 'Buy Bread']
    assert_match(
      /{"state":"new","title":"Buy Bread","modified":"\d{4}-\d{2}-\d{2}"}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_delete_todo
    read ['del', '1']
    assert_equal(
      '',
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_add_note
    read ['note', '1', 'test']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}","note":\["test"\]}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

  def test_delete_notes
    read ['delnote', '1']
    assert_match(
      /{"state":"new","title":"Buy Milk","modified":"\d{4}-\d{2}-\d{2}","note":\[\]}\n/,
      File.read("#{Dir.pwd}/todo.jsonl")
    )
  end

end
