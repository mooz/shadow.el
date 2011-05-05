# Shadow.el

> "Nobody knows the Java code you committed is originally written in Scheme."

Shadow.el is a [Shadow.vim](https://github.com/ujihisa/shadow.vim/) for Emacs which supports you code with a wrapper transparently in a pluggable way.

## Concept

See [Shadow.vim](https://github.com/ujihisa/shadow.vim/) for basic concept.

## Installation

Place shadow.el into your directory in `load-path', and put below lines in your Emacs configuration file.

    (require 'shadow)

If you want to open shadow file transparently, put below lines too.

    (add-hook 'find-file-hooks 'shadow-on-find-file)
    (add-hook 'shadow-find-unshadow-hook
              (lambda () (auto-revert-mode 1)))

By Enabling this setting, shadow.el opens `foo.bar.shd` automatically when you attempt to open `foo.bar` and enables `auto-revert-mode` in the `foo.bar`.

## Usage

While supporting Shadow.vim style simple command specification, Shadow.el also supports Emacs's file local variable style command specification.

Here are basic syntax of both styles.

### Shadow.vim style command specification

Shadow.vim style command specification takes command from the first line while skipping first 3 characters.

    ## tac
    #!/usr/bin/env ruby
    p :a
    p :b
    p :c

Actually, you can customize how many characters to skip and which line to use by setting values to `shadow-command-skip-count` and `shadow-command-line-number`.

### Emacs's file local variable style command specification

Since Shadow.vim style sometimes conflicts with Emacs's file local variable notation, Shadow.el arranges another choice; read command from file local variable itself.

When buffer local variable `shadow-command` is specified, this style is enabled.

    #!/usr/bin/env ruby
    # -*- mode: ruby; shadow-command: "tac"; -*-
    p :a
    p :b
    p :c

## Example

Commit JavaScript files which was written in CoffeeScript.

### Before

    ## coffee -csb
    f = (x) -> x + 1
    print f 10
    # Local Variables:
    # mode: coffee
    # End:

or,

    # -*- mode: coffee; shadow-command: "coffee -csb"; -*-
    f = (x) -> x + 1
    print f 10

### After

    var f;
    f = function(x) {
      return x + 1;
    };
    print(f(10));

## Author

mooz <stillpedant@gmail.com>
