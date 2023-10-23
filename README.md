# Smash

**S**cript **m**erging **a**pp for **sh**ell - a set of functions allowing to slice and dice bash scripts

**the tool is powered by zsh**, bash is not supported

## Usage

For example, to expand references to `shell` scripts in the same folder execute (for more details on this example see [tests](test)):

```sh
for file in $(smashd bar.sh); do echo $file; cat $(smash $file); done
```

## Installation

To install the tool, just clone the repo at `$HOME` directory and update your `.zshrc` config:

```sh
git clone git@github.com:zeionara/smash.git "$HOME/smash"
echo -e '\n. "$HOME/smash/.zshrc"' >> "$HOME/.zshrc"
```

## Testing

Alternatively, test script may be called:

`./test/test.sh`

The script expands file `test/bar.sh`, which has the following content:

```sh
#!/bin/bashh

echo 'foo'

qux

echo 'bax'

garply

echo 'mono'
```

and the following containing directory structure:

```sh
test
├── bar.sh
├── foo-expanded.sh
├── foo-updated.sh
├── foo.sh
├── garply
│   ├── fred.sh
│   └── waldo.sh
├── qux
│   ├── corge.sh
│   └── quux.sh
├── qux-quux.sh
└── test.sh
```

Into the following 4 files:

```sh
bar-expanded-qux=corge-garply=fred.sh
#!/bin/bashh

echo 'foo'

echo 'i am corge'

echo 'bax'

echo 'i am fred'

echo 'mono'

bar-expanded-qux=corge-garply=waldo.sh
#!/bin/bashh

echo 'foo'

echo 'i am corge'

echo 'bax'

echo 'i am waldo'

echo 'mono'

bar-expanded-qux=quux-garply=fred.sh
#!/bin/bashh

echo 'foo'

echo 'i am quux'

echo 'bax'

echo 'i am fred'

echo 'mono'

bar-expanded-qux=quux-garply=waldo.sh
#!/bin/bashh

echo 'foo'

echo 'i am quux'

echo 'bax'

echo 'i am waldo'

echo 'mono'
```
