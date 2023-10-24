# Smash

**S**cript **m**erging **a**pp for **sh**ell - a set of functions allowing to slice and dice bash scripts

**the tool is powered by zsh**, bash is not supported

## Usage

For example, to expand references to `shell` scripts in the same folder execute (for more details on this example see [tests](test)):

```sh
smasha bar.sh 'sudo apt-get install'
```

There are 4 separate functions supported:

1. smash - expand references to the scripts in the same folder (substitute content from the scripts instead of their name mentions);
1. smashd - expand references to files located in folders, mentioned in the script (substitude folder names with paths to specific files);
1. smashc - combine commands with given prefix by merging the lists of arguments and removing duplicates;
1. smasha - execute all operations listed above for the script located at given path.

## Installation

To install the tool, just clone the repo at `$HOME` directory and update your `.zshrc` config:

```sh
git clone git@github.com:zeionara/smash.git "$HOME/smash"
echo -e '\n. "$HOME/smash/.zshrc"' >> "$HOME/.zshrc"
```

## Testing

Alternatively, test script may be called:

```sh
./test/test.sh
```

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
bar-qux=corge-garply=fred.sh

#!/bin/bashh

echo 'foo'

echo 'i am corge'

sudo apt-get install foo bar baz qux corge garply

echo 'bax'

echo 'i am fred'

echo 'mono'


bar-qux=corge-garply=waldo.sh

#!/bin/bashh

echo 'foo'

echo 'i am corge'

sudo apt-get install foo bar baz qux

echo 'bax'

echo 'i am waldo'

echo 'mono'


bar-qux=quux-garply=fred.sh

#!/bin/bashh

echo 'foo'

echo 'i am quux'

echo 'bax'

echo 'i am fred'

sudo apt-get install baz qux corge garply

echo 'mono'


bar-qux=quux-garply=waldo.sh

#!/bin/bashh

echo 'foo'

echo 'i am quux'

echo 'bax'

echo 'i am waldo'

echo 'mono'
```
