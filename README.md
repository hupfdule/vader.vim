vader.vim
=========

I use Vader to test Vimscript.

### Vader test cases
![](https://raw.github.com/junegunn/i/master/vader.png)

### Vader result
![](https://raw.github.com/junegunn/i/master/vader-result.png)

Changes to upstream
-------------------

This is not the upstream source. It's a fork to fix some bugs that are not
incorporated into upstream yet.

The following pull requests are integrated:

 - [Display source with exceptions](https://github.com/junegunn/vader.vim/pull/107)
 - [Describe summary tab and default mappings in README](https://github.com/junegunn/vader.vim/pull/212)
 - [Provide foldexpr for  .vader files](https://github.com/junegunn/vader.vim/pull/213)
 - [Provide preview buffer](not yet a PR)

Additionally a fix is integrated to fix [Vader swallows Given lines](https://github.com/junegunn/vader.vim/issues/211). However as the consequences are unclear to me this was not made into a pull request.

Installation
------------

Use your favorite plugin manager.

- [vim-plug](https://github.com/junegunn/vim-plug)
  1. Add `Plug 'junegunn/vader.vim'` to .vimrc
  2. Run `:PlugInstall`

Running Vader tests
-------------------

- `Vader  [file glob ...]`
- `Vader! [file glob ...]`
    - Exit Vim after running the tests with exit status of 0 or 1
        - `vim '+Vader!*' && echo Success || echo Failure`
            - (You need to pass `--nofork` option when using GVim)
    - If the description of `Do` or `Execute` block includes `FIXME` or `TODO`,
      the block is recognized as a pending test case and does not affect the
      exit status.
    - If the environment variable `VADER_OUTPUT_FILE` is set, the test results
      will be written to it as well, otherwise they are written to stderr using
      different methods (depending on Neovim/Vim).

Syntax of .vader file
---------------------

A Vader file is a flat sequence of blocks each of which starts with the block
label, such as `Execute:`, followed by the content of the block indented by 2
spaces.

- Given
    - Content to fill the execution buffer
- Do
    - Normal-mode keystrokes that can span multiple lines
- Execute
    - Vimscript to execute
- Then
    - Vimscript to run after Do or Execute block. Used for assertions.
- Expect
    - Expected result of the preceding Do/Execute block
- Before
    - Vimscript to run before each test case
- After
    - Vimscript to run after each test case

If you want to skip 2-space indention, end the block label with a semi-colon
instead of a colon.

### Basic blocks

#### Given

The content of a Given block is pasted into the "workbench buffer" for the
subsequent Do/Execute blocks. If `filetype` parameter is given, `&filetype` of
the buffer is set accordingly. It is also used to syntax-highlight the block in
.vader file.

```
Given [filetype] [(comment)]:
  [input text]
```

#### Do

The content of a Do block is a sequence of normal-mode keystrokes that can
freely span multiple lines. A special key can be written in its name surrounded
by angle brackets preceded by a backslash (e.g. `\<Enter>`).

Do block can be followed by an optional Expect block.

```
Do [(comment)]:
  [keystrokes]
```

#### Execute

The content of an Execute block is plain Vimscript to be executed.

Execute block can also be followed by an optional Expect block.

```
Execute [(comment)]:
  [vimscript]
```

In Execute block, the following commands are provided.

- Assertions
    - `Assert <boolean expr>[, message]`
    - `AssertEqual <expected>, <got>[, message]`
    - `AssertNotEqual <unexpected>, <got>[, message]`
    - `AssertThrows <command>`
        - This will set `g:vader_exception` (from `v:exception`) and
          `g:vader_throwpoint` (from `v:throwpoint`).
- Other commands
    - `Log "Message"`
    - `Save <name>[, ...]`
    - `Restore [<name>, ...]`

The following syntax helper functions are provided:

- `SyntaxAt`: return a string with the name of the syntax group at the following position:
    - `SyntaxAt()`: current cursor position
    - `SyntaxAt(col)`: current cursor line, at given column
    - `SyntaxAt(lnum, col)`: line and column

- `SyntaxOf(pattern[, nth=1])`: return a string with the name of the syntax group
  at the first character of the nth match of the given pattern.
  Return `''` if there was no match.

The `.vader` file for the current test case path is available in
`g:vader_file`, which will not reflect included files (via `Include`).
The path of the actual file is available in `g:vader_current_file`.

In addition to plain Vimscript, you can also test Ruby/Python/Perl/Lua
interface with Execute block as follows:

```
Execute [lang] [(comment)]:
  [<lang> code]
```

See Ruby and Python examples
[here](https://github.com/junegunn/vader.vim/blob/master/test/feature/lang-if.vader).

#### Then

A Then block containing Vimscript can follow a Do or an Execute block. Mostly
used for assertions. Can be used in conjunction with an Expect block.

```
Then [(comment)]:
  [vimscript]
```

#### Expect

If an Expect block follows an Execute block or a Do block, the result of the
preceding block is compared to the content of the Expect block. Comparison is
case-sensitive. `filetype` parameter is used to syntax-highlight the block.

```
Expect [filetype] [(comment)]:
  [expected output]
```

### Hooks

#### Before

The content of a Before block is executed before every following
Do/Execute block.

```
Before [(comment)]:
  [vim script]
```

#### After

The content of an After block is executed after every following
Do/Execute block.

```
After [(comment)]:
  [vim script]
```

### Macros

#### Include

You can include other vader files using Include macro.

```
Include: setup.vader

# ...

Include: cleanup.vader
```

### Comments

Any line that starts with `#`, `"`, `=`, `-`, `~`, `^`, or `*` without
indentation is considered to be a comment and simply ignored.

    ###################
    # Typical comment #
    ###################

    Given (fixture):
    ================
      Hello

    Do (modification):
    ------------------
    * change inner word
      ciw
    * to
      World

    Expect (result):
    ~~~~~~~~~~~~~~~~
      World

### Example

```
# Test case
Execute (test assertion):
  %d
  Assert 1 == line('$')

  setf python
  AssertEqual 'python', &filetype

Given ruby (some ruby code):
  def a
    a = 1
    end

Do (indent the block):
  vip=

Expect ruby (indented block):
  def a
    a = 1
  end

Do (indent and shift):
  vip=
  gv>

Expect ruby (indented and shifted):
    def a
      a = 1
    end

Given c (C file):
  int i = 0;

Execute (syntax is good):
  AssertEqual SyntaxAt(2), 'cType'
  AssertEqual SyntaxOf('0'), 'cNumber'
```

Folding of .vader files
-----------------------

Folding of .vader files can be enabled by setting the the
`g:vader_enable_folding` to 1. This will set `foldmethod` to `expr` and
declare a corresponding fold expression.

Previewing the workbench buffer in a separate window
----------------------------------------------------

The content of the workbench buffer can be previewed in a separate window
while modifying a `.vader` file. 
This is helpful when writing the verification code to have the content
under test directly visible, especially when referring to specific line
numbers in the test fixture.

At the moment only the content of `:Given` block can be previewed, but not
the result of the `:Do` block.

The filetype of the preview buffer is set to the filetype specified in the
`Given:` block.

While the preview window is open its content is automatically adjusted if
the cursor is moved to another block in the `.vader` file.

<!-- TODO: Screenshot -->

The preview window can be shown/hidden with the following commands:

- `:VaderPreview[!]`
  - Open the preview buffer in a separate window. If the bang (!) is given
    the window of the preview buffer is closed instead.
- `:VaderPreviewToggle`
  - Toggle the visibility of the preview window.

The following <Plug>-mappings are provided to map these commands to
keystrokes:

- `<Plug>(VaderPreviewOpen)`
  - Open the preview window.
- `<Plug>(VaderPreviewClose)`
  - Close the preview window.
- `<Plug>(VaderPreviewToggle)`
  - Toggle the visibility of the preview window.

There are no default keybindings for these mappings. They can be assigned to
keys via e.g.:

```
nmap <leader>p <Plug>(VaderPreviewToggle)
```


Running tests from within vim
-----------------------------

When running interactively the `:Vader` command opens the test results in a
separate tab.  This is helpful for immediate feedback while developing a
plugin.

In this tab a window displays the actual test results as can be seen in the
screenshots above.

If there were test failures these will be filled into the quickfix list and
the quickfix window is opened.

When navigating the items in the quickfix list, another window is opened
with the selected error location.


Mappings
--------

Vader provides some useful mappings:

- Inside a vader file the common keys for section navigation (`]]`, `[[`,
  `][`, `[]`) can be used to jump between the vader blocks.
- When inside the vader summary tab `q` can be used to close the summary
  tab.


Setting up isolated testing environment
---------------------------------------

When you test a plugin, it's generally a good idea to setup a testing
environment that is isolated from the other plugins and settings irrelevant to
the test. The simplest way to achieve this is to start Vim with a mini
.vimrc as follows:

```sh
vim -Nu <(cat << EOF
filetype off
set rtp+=~/.vim/bundle/vader.vim
set rtp+=~/.vim/bundle/vim-markdown
set rtp+=~/.vim/bundle/vim-markdown/after
filetype plugin indent on
syntax enable
EOF) +Vader*
```

Travis CI integration
---------------------

To make your project tested on [Travis CI](https://travis-ci.org), you need to
add `.travis.yml` to your project root. For most plugins the following example
should suffice.

```yaml
language: vim

before_script: |
  git clone https://github.com/junegunn/vader.vim.git

script: |
  vim -Nu <(cat << VIMRC
  filetype off
  set rtp+=vader.vim
  set rtp+=.
  set rtp+=after
  filetype plugin indent on
  syntax enable
  VIMRC) -c 'Vader! test/*' > /dev/null
```

(Note that `vim` is not a valid language for Travis CI. It just sets up Ruby
execution environment instead as the default.)

### Examples

- [Simple .travis.yml](https://github.com/junegunn/seoul256.vim/blob/master/.travis.yml)
    - [Build result](https://travis-ci.org/junegunn/seoul256.vim/builds/23905890)
- [Advanced .travis.yml](https://github.com/junegunn/vim-oblique/blob/master/.travis.yml)
    - Multiple dependencies
    - Builds Vim from source
    - [Build result](https://travis-ci.org/junegunn/vim-oblique/builds/25033116)

Projects using Vader
--------------------

See [the wiki page](https://github.com/junegunn/vader.vim/wiki/Projects-using-Vader).

Known issues
------------

### feedkeys() cannot be tested

The keystrokes given to the feedkeys() function are consumed only after Vader
finishes executing the content of the Do/Execute block. Take the following case
as an example:

```vim
Do (Test feedkeys() function):
  i123
  \<C-O>:call feedkeys('456')\<CR>
  789

Expect (Wrong!):
  123456789
```

You may have expected `123456789`, but the result is `123789456`. Unfortunately
I have yet to find a workaround for this problem. Please let me know if you find
one.

### Some events may not be triggered

[It is reported](https://github.com/junegunn/vader.vim/issues/2) that
CursorMoved event is not triggered inside a Do block. If you need to test a
feature that involves autocommands on CursorMoved event, you have to manually
invoke it in the middle of the block using `:doautocmd`.

```vim
Do (Using doautocmd):
  jjj
  :doautocmd CursorMoved\<CR>
```

### Search history may not be correctly updated

This is likely a bug of Vim itself. For some reason, search history is not
correctly updated when searches are performed inside a Do block. The following
test scenario fails due to this problem.

```vim
Execute (Clear search history):
  for _ in range(&history)
    call histdel('/', -1)
  endfor

Given (Search and destroy):
  I'm a street walking cheetah with a heart full of napalm
  I'm a runaway son of the nuclear A-bomb
  I'm a world's forgotten boy
  The one who searches and destroys

Do (Searches):
  /street\<CR>
  /walking\<CR>
  /cheetah\<CR>
  /runaway\<CR>
  /search\<CR>

Execute (Assertions):
  Log string(map(range(1, &history), 'histget("/", - v:val)'))
  AssertEqual 'runaway', histget('/', -2)
  AssertEqual 'search', histget('/', -1)
```

The result is given as follows:

```vim
Starting Vader: 1 suite(s), 3 case(s)
  Starting Vader: /Users/jg/.vim/plugged/vader.vim/search-and-destroy.vader
    (1/3) [EXECUTE] Clear search history
    (2/3) [  GIVEN] Search and destroy
    (2/3) [     DO] Searches
    (3/3) [  GIVEN] Search and destroy
    (3/3) [EXECUTE] Assertions
      > ['search', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '']
    (3/3) [EXECUTE] (X) Assertion failure: 'runaway' != ''
  Success/Total: 2/3
Success/Total: 2/3 (assertions: 0/1)
Elapsed time: 0.36 sec.
```

License
-------

MIT
