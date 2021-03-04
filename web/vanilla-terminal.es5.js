(function() {
  var $jscomp = $jscomp || {};
  $jscomp.scope = {};
  $jscomp.createTemplateTagFirstArg = function(a) {
    return a.raw = a;
  };
  $jscomp.createTemplateTagFirstArgWithRaw = function(a, b) {
    a.raw = b;
    return a;
  };
  $jscomp.arrayIteratorImpl = function(a) {
    var b = 0;
    return function() {
      return b < a.length ? {done:!1, value:a[b++], } : {done:!0};
    };
  };
  $jscomp.arrayIterator = function(a) {
    return {next:$jscomp.arrayIteratorImpl(a)};
  };
  $jscomp.makeIterator = function(a) {
    var b = "undefined" != typeof Symbol && Symbol.iterator && a[Symbol.iterator];
    return b ? b.call(a) : $jscomp.arrayIterator(a);
  };
  $jscomp.arrayFromIterator = function(a) {
    for (var b, d = []; !(b = a.next()).done;) {
      d.push(b.value);
    }
    return d;
  };
  var KEY = "VanillaTerm", $jscomp$destructuring$var0 = window, addEventListener = $jscomp$destructuring$var0.addEventListener, cloneCommandNode = function(a) {
    a = a.cloneNode(!0);
    var b = a.querySelector(".input");
    b.autofocus = !1;
    b.readOnly = !0;
    b.insertAdjacentHTML("beforebegin", b.value);
    b.parentNode.removeChild(b);
    a.classList.add("line");
    return a;
  }, markup = function(a) {
    a = a.shell;
    return '\n<div class="container">\n<output></output>\n<div class="command">\n<div class="prompt">' + a.prompt + a.separator + '</div>\n<input class="input" spellcheck="false" autofocus />\n</table>\n</div>\n';
  }, COMMANDS = {clear:function(a) {
    return a.clear();
  }, commands:function(a) {
    a.output("These shell commands are defined internally:");
    a.output(Object.keys(a.commands).join(", "));
  }, }, Terminal = function(a) {
    var b = this, d = a = void 0 === a ? {} : a;
    a = void 0 === d.container ? "vanilla-terminal" : d.container;
    var q = void 0 === d.defaultCallback ? null : d.defaultCallback, l = void 0 === d.welcome ? 'Welcome to <a href="">Vanilla</a> terminal.' : d.welcome, r = void 0 === d.prompt ? "" : d.prompt, t = void 0 === d.separator ? "&gt;" : d.separator;
    this.commands = Object.assign({}, void 0 === d.commands ? {} : d.commands, COMMANDS);
    this.defaultCallback = q;
    this.history = [];
    this.historyCursor = this.history.length;
    this.welcome = l;
    this.shell = {prompt:r, separator:t};
    this.state = {prompt:void 0, idle:void 0, };
    this.cacheDOM = function(c) {
      c.classList.add(KEY);
      c.insertAdjacentHTML("beforeEnd", markup(b));
      c = c.querySelector(".container");
      b.DOM = {container:c, output:c.querySelector("output"), command:c.querySelector(".command"), input:c.querySelector(".command .input"), prompt:c.querySelector(".command .prompt"), };
    };
    this.addListeners = function() {
      var c = b.DOM;
      c.output.addEventListener("DOMSubtreeModified", function() {
        setTimeout(function() {
          return c.input.scrollIntoView();
        }, 10);
      }, !1);
      addEventListener("click", function() {
        return c.input.focus();
      }, !1);
      c.output.addEventListener("click", function(e) {
        return e.stopPropagation();
      }, !1);
      c.input.addEventListener("keyup", b.onKeyUp, !1);
      c.input.addEventListener("keydown", b.onKeyDown, !1);
      c.command.addEventListener("click", function() {
        return c.input.focus();
      }, !1);
      addEventListener("keyup", function(e) {
        c.input.focus();
        e.stopPropagation();
        e.preventDefault();
      }, !1);
    };
    this.onKeyUp = function(c) {
      var e = c.keyCode, g = b.DOM, f = void 0 === b.history ? [] : b.history, h = b.historyCursor;
      27 === e ? (g.input.value = "", c.stopPropagation(), c.preventDefault()) : [38, 40].includes(e) && (38 === e && 0 < h && --b.historyCursor, 40 === e && h < f.length - 1 && (b.historyCursor += 1), f[b.historyCursor] && (g.input.value = f[b.historyCursor]));
    };
    this.onKeyDown = function(c) {
      var e = c.keyCode, g = void 0 === b.commands ? {} : b.commands, f = b.DOM, h = b.history;
      c = b.onInputCallback;
      var n = b.defaultCallback, p = b.state, m = f.input.value.trim();
      if (13 === e && m) {
        var k = $jscomp.makeIterator(m.trim().split(/[\s|\u00A0]+/));
        e = k.next().value;
        k = $jscomp.arrayFromIterator(k);
        p.prompt ? (p.prompt = !1, b.onAskCallback(e), b.setPrompt(), b.resetCommand()) : (100 <= h.length && h.shift(), h.push(m), b.historyCursor = h.length, f.output.appendChild(cloneCommandNode(f.command)), f.command.classList.add("hidden"), f.input.value = "", Object.keys(g).includes(e) ? ((g = g[e]) && g(b, k), c && c(e, k)) : n ? n(b, e, k) : b.output("<u>" + e + "</u>: command not found."));
      }
    };
    this.resetCommand = function() {
      var c = b.DOM;
      c.input.value = "";
      c.command.classList.remove("input");
      c.command.classList.remove("hidden");
      c.input.scrollIntoView && c.input.scrollIntoView();
    };
    if (d = document.getElementById(a)) {
      this.cacheDOM(d), this.addListeners(), l && this.output(l);
    } else {
      throw Error("Container #" + a + " doesn't exists.");
    }
  };
  Terminal.prototype.clear = function() {
    this.DOM.output.innerHTML = "";
    this.resetCommand();
  };
  Terminal.prototype.idle = function() {
    var a = this.DOM;
    a.command.classList.add("idle");
    a.prompt.innerHTML = '<div class="spinner"></div>';
  };
  Terminal.prototype.prompt = function(a, b) {
    this.state.prompt = !0;
    this.onAskCallback = void 0 === b ? function() {
    } : b;
    this.DOM.prompt.innerHTML = a + ":";
    this.resetCommand();
    this.DOM.command.classList.add("input");
  };
  Terminal.prototype.onInput = function(a) {
    this.onInputCallback = a;
  };
  Terminal.prototype.output = function(a) {
    this.DOM.output.insertAdjacentHTML("beforeEnd", "<span>" + (void 0 === a ? "&nbsp;" : a) + "</span>");
    this.resetCommand();
  };
  Terminal.prototype.setPrompt = function(a) {
    a = void 0 === a ? this.shell.prompt : a;
    var b = this.DOM, d = this.shell.separator;
    this.shell = {prompt:a, separator:d};
    b.command.classList.remove("idle");
    b.prompt.innerHTML = "" + a + d;
    b.input.focus();
  };
  window && (window.VanillaTerminal = Terminal);
})();
