# vanilla-terminal

> 🍦A simple and lightweight Javascript web browser terminal

Web apps are great. But sometimes instead of all the double-clicks, mouse pointers, taps and swipes across the screen - you just want good old keyboard input. This terminal runs in a browser, desktop or mobile. It provides a simple and easy way to extend the terminal with your own commands.

## How to use
Include `vanilla-terminal.js` in your HTML:

```html
<script src="vanilla-terminal.min.js"></script>
```

Define an HTML div tag where the terminal will be contained:

```html
<div id="vanilla-terminal"></div>
```

Create a new terminal instance and convert the DOM element into a live terminal.

```js
const terminal = new VanillaTerminal();
```

If you want use another DOM element as container just set the property `container`:

```js
const terminal = new VanillaTerminal({ container: 'my-vanilla-container' });
```

### Add your own commands
If you want add your own commands to the terminal just pass a object using the *property* as your command and the *value* as the callback.

```js
const commands = {
  flavour: (instance) => {
    instance.output('There is only one flavour for your favorite🍦and it is <b>vanilla<b>.')
    instance.setPrompt('@soyjavi <small>❤️</small> <u>vanilla</u> ');
  },

  ping: (instance, parameters) => {
    instance.output('Ping to <u>${parameters[0]}</u>...');
  },
};

const terminal = new VanillaTerminal({ commands });
```

Now in your terminal could type your new commands:

```bash
> commands
These shell commands are defined internally:
flavour, ping, clear, commands, version, wipe

> flavour
There is only one flavour for your favorite🍦and it is vanilla.
@soyjavi ❤️ vanilla >
```

## Methods

### clear

```js
terminal.clear();
```

### output

```js
terminal.output('I like vanilla.');
```

```bash
I like vanilla.
>
```

### prompt

```js
terminal.prompt('Type your name', (name) => {
  terminal.output(`Hi ${name}!`);
});
```

```bash
Type your name: javi
Hi javi!
>
```

### onInput

```js
terminal.onInput((command, parameters) => {
  console.log('⚡️onInput', command, parameters);
});
```

### setPrompt

```js
terminal.setPrompt('soyjavi @ moon');
```

```bash
soyjavi @ moon >
```

## License

Copyright (c) 2018 Javier Jimenez Villar

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
