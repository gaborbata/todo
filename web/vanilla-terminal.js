(function() {
  const KEY = 'VanillaTerm';
  const { addEventListener } = window;

  const cloneCommandNode = (el) => {
    const line = el.cloneNode(true);
    const input = line.querySelector('.input');

    input.autofocus = false;
    input.readOnly = true;
    input.insertAdjacentHTML('beforebegin', input.value);
    input.parentNode.removeChild(input);
    line.classList.add('line');

    return line;
  };

  const markup = ({ shell: { prompt, separator } }) => (`
    <div class="container">
      <output></output>
      <div class="command">
        <div class="prompt">${prompt}${separator}</div>
        <input class="input" spellcheck="false" autofocus />
      </table>
    </div>
  `);

  const COMMANDS = {
    clear: terminal => terminal.clear(),

    commands: (terminal) => {
      terminal.output('These shell commands are defined internally:');
      terminal.output(Object.keys(terminal.commands).join(', '));
    },

  };

  class Terminal {
    constructor(props = {}) {
      const {
        container = 'vanilla-terminal',
        commands = {},
        defaultCallback = null,
        welcome = 'Welcome to <a href="">Vanilla</a> terminal.',
        prompt = '',
        separator = '&gt;',
      } = props;
      this.commands = Object.assign({}, commands, COMMANDS);
      this.defaultCallback = defaultCallback;
      this.history = [];
      this.historyCursor = this.history.length;
      this.welcome = welcome;
      this.shell = { prompt, separator };

      this.state = {
        prompt: undefined,
        idle: undefined,
      };

      this.cacheDOM = (el) => {
        el.classList.add(KEY);
        el.insertAdjacentHTML('beforeEnd', markup(this));

        // Cache DOM nodes
        const container = el.querySelector('.container');
        this.DOM = {
          container,
          output: container.querySelector('output'),
          command: container.querySelector('.command'),
          input: container.querySelector('.command .input'),
          prompt: container.querySelector('.command .prompt'),
        };
      };

      this.addListeners = () => {
        const { DOM } = this;
        DOM.output.addEventListener('DOMSubtreeModified', () => {
          setTimeout(() => DOM.input.scrollIntoView(), 10);
        }, false);

        addEventListener('click', () => DOM.input.focus(), false);
        DOM.output.addEventListener('click', event => event.stopPropagation(), false);
        DOM.input.addEventListener('keyup', this.onKeyUp, false);
        DOM.input.addEventListener('keydown', this.onKeyDown, false);
        DOM.command.addEventListener('click', () => DOM.input.focus(), false);

        addEventListener('keyup', (event) => {
          DOM.input.focus();
          event.stopPropagation();
          event.preventDefault();
        }, false);
      };

      this.onKeyUp = (event) => {
        const { keyCode } = event;
        const { DOM, history = [], historyCursor } = this;

        if (keyCode === 27) { // ESC key
          DOM.input.value = '';
          event.stopPropagation();
          event.preventDefault();
        } else if ([38, 40].includes(keyCode)) {
          if (keyCode === 38 && historyCursor > 0) this.historyCursor -= 1; // {38} UP key
          if (keyCode === 40 && historyCursor < history.length - 1) this.historyCursor += 1; // {40} DOWN key

          if (history[this.historyCursor]) DOM.input.value = history[this.historyCursor];
        }
      };

      this.onKeyDown = ({ keyCode }) => {
        const {
          commands = {}, DOM, history, onInputCallback, defaultCallback, state,
        } = this;
        const commandLine = DOM.input.value.trim();
        if (keyCode !== 13 || (!defaultCallback && !commandLine)) return;

        const [command, ...parameters] = commandLine.trim().split(/[\s\u00A0]+/);

        if (state.prompt) {
          state.prompt = false;
          this.onAskCallback(command);
          this.setPrompt();
          this.resetCommand();
          return;
        }

        // Save command line in history
        if (!!commandLine) {
          if (history.length >= 100) {
            history.shift();
          }
          history.push(commandLine);
        }
        this.historyCursor = history.length;

        // Clone command as a new output line
        DOM.output.appendChild(cloneCommandNode(DOM.command));

        // Clean command line
        DOM.command.classList.add('hidden');
        DOM.input.value = '';

        // Dispatch command
        if (Object.keys(commands).includes(command)) {
          const callback = commands[command];
          if (callback) callback(this, parameters);
          if (onInputCallback) onInputCallback(command, parameters);
        } else {
          if (defaultCallback) {
            defaultCallback(this, command, parameters);
          } else {
            this.output(`<u>${command}</u>: command not found.`);
          }
        }
      };

      this.resetCommand = () => {
        const { DOM } = this;

        DOM.input.value = '';
        DOM.command.classList.remove('input');
        DOM.command.classList.remove('hidden');
        if (DOM.input.scrollIntoView) DOM.input.scrollIntoView();
      };

      const el = document.getElementById(container);
      if (el) {
        this.cacheDOM(el);
        this.addListeners();
        if (welcome) this.output(welcome);
      } else throw Error(`Container #${container} doesn't exists.`);
    }

    clear() {
      this.DOM.output.innerHTML = '';
      this.resetCommand();
    }

    idle() {
      const { DOM } = this;
      DOM.command.classList.add('idle');
      DOM.prompt.innerHTML = '<div class="spinner"></div>';
    }

    prompt(prompt, callback = () => {}) {
      this.state.prompt = true;
      this.onAskCallback = callback;
      this.DOM.prompt.innerHTML = `${prompt}:`;
      this.resetCommand();
      this.DOM.command.classList.add('input');
    }

    onInput(callback) {
      this.onInputCallback = callback;
    }

    output(html = '&nbsp;') {
      this.DOM.output.insertAdjacentHTML('beforeEnd', `<span>${html}</span>`);
      this.resetCommand();
    }

    setPrompt(prompt = this.shell.prompt) {
      const { DOM, shell: { separator } } = this;

      this.shell = { prompt, separator };
      DOM.command.classList.remove('idle');
      DOM.prompt.innerHTML = `${prompt}${separator}`;
      DOM.input.focus();
    }
  }

  if (window) window.VanillaTerminal = Terminal;
})();
