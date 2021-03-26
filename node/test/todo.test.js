const execSync = require('child_process').execSync
const assert = require('chai').assert
const fs = require('fs')
const os = require('os')
const path = require('path')
const today = () => new Date().toISOString().replace(/T.+/, '')
let todoPath

describe("todo list manager", () => {
  before("setup environment", () => {
    const originalHomeDir = os.homedir()
    process.env.HOME = process.cwd()
    process.env.USERPROFILE = process.cwd()
    assert.notEqual(originalHomeDir, os.homedir())
    todoPath = path.join(process.cwd(), 'todo.jsonl')
  })

  beforeEach("add initial task", () => {
    if (fs.existsSync(todoPath)) {
      fs.unlinkSync(todoPath)
    }
    execSync('node todo.js add Buy Milk')
  })

  afterEach("delete todo file", () => {
    if (fs.existsSync(todoPath)) {
      fs.unlinkSync(todoPath)
    }
  })

  it("should add new todo", () => {
    const output = execSync('node todo.js list').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk\n")
  })

  it("should start todo", () => {
    const output = execSync('node todo.js start 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"started", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[32m[>]\u001b[0m Buy Milk\n")
  })

  it("should reset todo", () => {
    execSync('node todo.js start 1')
    const output = execSync('node todo.js reset 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk\n")
  })

  it("should not start non existing todo", () => {
    const output = execSync('node todo.js start 2').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "\u001b[31mERROR:\u001b[0m RuntimeError: 2: No such todo\n")
  })

  it("should complete todo", () => {
    const output = execSync('node todo.js done 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"done", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "No todos found\n")
  })

  it("should block todo", () => {
    const output = execSync('node todo.js block 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"blocked", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[33m[!]\u001b[0m Buy Milk\n")
  })

  it("should set priority", () => {
    const output = execSync('node todo.js prio 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}", "priority":true}\r?\n/
    )
    assert.equal(output, "   1:\u001b[31m*\u001b[0m\u001b[37m[ ]\u001b[0m Buy Milk\n")
  })

  it("should set priority with note", () => {
    const output = execSync('node todo.js prio 1 "very important"').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}", "priority":true, "note":\["very important"\]}\r?\n/
    )
    assert.equal(output, "   1:\u001b[31m*\u001b[0m\u001b[37m[ ]\u001b[0m Buy Milk\n")
  })

  it("should set due date", () => {
    const output = execSync('node todo.js due 1 ' + today()).toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}", "due":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk \u001b[33m(today)\u001b[0m\n")
  })

  it("should unset due date", () => {
    execSync('node todo.js due 1 ' + today())
    const output = execSync('node todo.js due 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk\n")
  })

  it("should set due date via tag", () => {
    execSync('node todo.js del 1')
    const output = execSync('node todo.js add "Buy Milk ASAP due:' + today() + '"').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk ASAP", "modified":"\d{4}-\d{2}-\d{2}", "due":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk ASAP \u001b[33m(today)\u001b[0m\n")
  })

  it("should set due date via tag with day name", () => {
    execSync('node todo.js del 1')
    const output = execSync('node todo.js add "Buy Milk ASAP due:Friday"').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk ASAP", "modified":"\d{4}-\d{2}-\d{2}", "due":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
  })

  it("should set due date via tag with short day name", () => {
    execSync('node todo.js del 1')
    const output = execSync('node todo.js add "Buy Milk ASAP due:wed"').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk ASAP", "modified":"\d{4}-\d{2}-\d{2}", "due":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
  })

  it("should set due date via tag with simple day name", () => {
    execSync('node todo.js del 1')
    const output = execSync('node todo.js add "Buy Milk ASAP due:tomorrow"').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk ASAP", "modified":"\d{4}-\d{2}-\d{2}", "due":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk ASAP \u001b[33m(tomorrow)\u001b[0m\n")
  })

  it("should set due date via tag in rename", () => {
    const output = execSync('node todo.js rename 1 "Buy Milk ASAP due:' + today() + '"').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk ASAP", "modified":"\d{4}-\d{2}-\d{2}", "due":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk ASAP \u001b[33m(today)\u001b[0m\n")
  })

  it("should toggle priority", () => {
    execSync('node todo.js prio 1')
    const output = execSync('node todo.js prio 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk\n")
  })

  it("should append text to todo title", () => {
    const output = execSync('node todo.js append 1 ASAP').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk ASAP", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk ASAP\n")
  })

  it("should rename todo", () => {
    const output = execSync('node todo.js rename 1 "Buy Bread"').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Bread", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Bread\n")
  })

  it("should delete todo", () => {
    const output = execSync('node todo.js del 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /\s+/
    )
    assert.equal(output, "No todos found\n")
  })

  it("should not delete non exiting todo", () => {
    const output = execSync('node todo.js del 42').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "\u001b[31mERROR:\u001b[0m RuntimeError: 42: No such todo\n")
  })

  it("should reorganize numbers when deleting todo", () => {
    execSync('node todo.js add "Buy Rice"')
    const output = execSync('node todo.js del 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Rice", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Rice\n")
  })

  it("should add note", () => {
    const output = execSync('node todo.js note 1 test').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}", "note":\["test"\]}\r?\n/
    )
    assert.match(
      output,
      /\u001b\[36m {5}state:\u001b\[0m new\n\u001b\[36m {5}title:\u001b\[0m Buy Milk\n\u001b\[36m  modified:\u001b\[0m \d{4}-\d{2}-\d{2}\n\u001b\[36m {6}note:\u001b\[0m \ntest\n/
    )
  })

  it("should delete all notes", () => {
    execSync('node todo.js note 1 "a note"')
    const output = execSync('node todo.js delnote 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.match(
      output,
      /\u001b\[36m {5}state:\u001b\[0m new\n\u001b\[36m {5}title:\u001b\[0m Buy Milk\n\u001b\[36m  modified:\u001b\[0m \d{4}-\d{2}-\d{2}\n/
    )
  })

  it("should delete a specific note", () => {
    execSync('node todo.js note 1 "first note"')
    execSync('node todo.js note 1 "second note"')
    const output = execSync('node todo.js delnote 1 2').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}", "note":\["first note"\]}\r?\n/
    )
    assert.match(
      output,
      /\u001b\[36m {5}state:\u001b\[0m new\n\u001b\[36m {5}title:\u001b\[0m Buy Milk\n\u001b\[36m  modified:\u001b\[0m \d{4}-\d{2}-\d{2}\n\u001b\[36m {6}note:\u001b\[0m \nfirst note\n/
    )
  })

  it("should delete entire note when deleting the last note entry", () => {
    execSync('node todo.js note 1 first note')
    const output = execSync('node todo.js delnote 1 1').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.match(
      output,
      /\u001b\[36m {5}state:\u001b\[0m new\n\u001b\[36m {5}title:\u001b\[0m Buy Milk\n\u001b\[36m  modified:\u001b\[0m \d{4}-\d{2}-\d{2}\n/
    )
  })

  it("should not delete non existing note", () => {
    const output = execSync('node todo.js delnote 1 1').toString()
    assert.equal(output, "\u001b[31mERROR:\u001b[0m RuntimeError: 1: Note does not exist\n")
  })

  it("should change state with note", () => {
    const output = execSync('node todo.js block 1 note').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"blocked", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}", "note":\["note"\]}\r?\n/
    )
  })

  it("should list todos when called without parameters", () => {
    const output = execSync('node todo.js').toString()
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk\n")
  })

  it("should show todo", () => {
    const output = execSync('node todo.js show 1').toString()
    assert.match(
      output,
      /\u001b\[36m {5}state:\u001b\[0m new\n\u001b\[36m {5}title:\u001b\[0m Buy Milk\n\u001b\[36m  modified:\u001b\[0m \d{4}-\d{2}-\d{2}\n/
    )
  })

  it("should list by context tag", () => {
    execSync('node todo.js add "Buy Bread @breakfast"')
    const output = execSync('node todo.js list @breakfast').toString()
    assert.equal(output, "   2: \u001b[37m[ ]\u001b[0m Buy Bread \u001b[36m@breakfast\u001b[0m\n")
  })

  it("should list by project tag", () => {
    execSync('node todo.js add "Buy Bread +breakfast"')
    const output = execSync('node todo.js list "\\+breakfast"').toString()
    assert.equal(output, "   2: \u001b[37m[ ]\u001b[0m Buy Bread \u001b[36m+breakfast\u001b[0m\n")
  })

  it("should list all by pre-defined query", () => {
    execSync('node todo.js done 1')
    const output = execSync('node todo.js list :all').toString()
    assert.equal(output, "   1: \u001b[34m[x]\u001b[0m Buy Milk\n")
  })

  it("should list active tasks by default", () => {
    execSync('node todo.js append 1 @breakfast')
    execSync('node todo.js done 1')
    execSync('node todo.js add "Buy Bread @breakfast"')
    const output = execSync('node todo.js list @breakfast').toString()
    assert.equal(output, "   2: \u001b[37m[ ]\u001b[0m Buy Bread \u001b[36m@breakfast\u001b[0m\n")
  })

  it("should list recently updated tasks", () => {
    const output = execSync('node todo.js list :recent').toString()
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk\n")
  })

  it("should not list with non matching multiple regex", () => {
    const output = execSync('node todo.js list milk bread').toString()
    assert.equal(output, "No todos found\n")
  })

  it("should list by due date", () => {
    execSync('node todo.js due 1 ' + today())
    execSync('node todo.js add "Buy Bread @unplanned"')
    const output = execSync('node todo.js list :today').toString()
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk \u001b[33m(today)\u001b[0m\n")
  })

  it("should list by next 7 days", () => {
    execSync('node todo.js due 1 tomorrow')
    execSync('node todo.js add "Buy Bread @unplanned"')
    const output = execSync('node todo.js list :next7days').toString()
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk \u001b[33m(tomorrow)\u001b[0m\n")
  })

  it("should list overdue tasks", () => {
    execSync('node todo.js add "Opean Tutankhamen\'s burial chamber due:1923-02-16"')
    const output = execSync('node todo.js list :overdue').toString()
    assert.match(output, /   2: \u001b\[37m\[ \]\u001b\[0m Opean Tutankhamen's burial chamber \u001b\[31m\(\d+d overdue\)\u001b\[0m\n/)
  })

  it("should list tasks with due dates", () => {
    execSync('node todo.js due 1 tomorrow')
    execSync('node todo.js add "Buy Bread @unplanned"')
    const output = execSync('node todo.js list :due').toString()
    assert.equal(output, "   1: \u001b[37m[ ]\u001b[0m Buy Milk \u001b[33m(tomorrow)\u001b[0m\n")
  })

  it("should list tasks with notes", () => {
    execSync('node todo.js add "Buy Bread"')
    execSync('node todo.js note 2 "a note"')
    const output = execSync('node todo.js list :note').toString()
    assert.equal(output, "   2: \u001b[37m[ ]\u001b[0m Buy Bread\n")
  })

  it("should list priority tasks", () => {
    execSync('node todo.js add "Very important task"')
    execSync('node todo.js prio 2')
    const output = execSync('node todo.js list :priority').toString()
    assert.equal(output, "   2:\u001b[31m*\u001b[0m\u001b[37m[ ]\u001b[0m Very important task\n")
  })

  it("should throw error on invalid date", () => {
    const output = execSync('node todo.js due 1 kedd').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Milk", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "\u001b[31mERROR:\u001b[0m ArgumentError: invalid date\n")
  })

  it("should not cleanup with non matching todos", () => {
    execSync('node todo.js rename 1 "Buy Bread @breakfast"')
    const output = execSync('node todo.js cleanup @breakfast').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Bread @breakfast", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "Deleted 0 todo(s)\n")
  })

  it("should cleanup", () => {
    execSync('node todo.js rename 1 "Buy Bread @breakfast"')
    execSync('node todo.js add "Buy Eggs @breakfast"')
    execSync('node todo.js done 1')
    const output = execSync('node todo.js cleanup @breakfast').toString()
    assert.match(
      fs.readFileSync(todoPath, 'utf8'),
      /{"state":"new", "title":"Buy Eggs @breakfast", "modified":"\d{4}-\d{2}-\d{2}"}\r?\n/
    )
    assert.equal(output, "Deleted 1 todo(s)\n")
  })
})
