![][image]

## About

`jammer` is a tool for punishing yourself (or other unsuspecting people)
for inefficiently using Emacs.

## Installation

Install from [MELPA] with `M-x package-install RET jammer RET`.

## Usage

Enable it interactively with `M-x jammer-mode` or by adding the
following to your init file:

    (jammer-mode)

## Customization

`jammer` comes with the `repeat` type enabled out of the box which
punishes you for repeating keystrokes too quickly.  You can customize
the base delay (`jammer-repeat-delay`), the repetition window
(`jammer-repeat-window`), amount of allowed repetitions
(`jammer-repeat-allowed-repetitions`) and most importantly, the type
of slowdown (`jammer-repeat-type`).  It can be constant, linear or
quadratic, the latter two types increase the delay time depending on
the repetition count.

Asides from the `repeat` type, there's also the option to constantly
slow down all events (for input lag emulation) or misfiring and
slowing down randomly selected events by a random amount, an effect
most comparable to having spilt a small amount of a sticky liquid on
your keyboard.  These can be enabled by customizing `jammer-type`.

Finally, one can whitelist or blacklist commands.  By default an empty
whitelist is used.  Adding a command to `jammer-block-list` in this
state of operation will make it exempt to all delays,
`self-insert-command` would be an useful example to allow typing
normally, but slowing down other repetitive commands.  Changing
`jammer-block-type` to `blacklist` will change the behaviour to not
affecting anything by default.  If `jammer-block-list` were to contain
`previous-line`, `next-line`, `left-char` and `right-char`, slowdowns
will only happen for the use of arrow keys for text movement.

## Alternatives

This package is heavily inspired by [vim-molasses] which is inspired
by [vim-hardtime] which is inspired by [hardmode].

I'm not aware of any Emacs alternatives, but [annoying-arrows-mode],
[hardcore-mode] and [guru-mode] come somewhat close.

## Motivation

Some people believe rate-limiting their bad keyboard habits is the way
to go.  Though, this belief seems to be rather linked to Vim, not
Emacs.  I intended to find out how hard it is to achieve this goal
programmatically, however I've learned about a much more interesting
thing, compatibility of post-command sleep with other Emacs packages.
If used on its own, the package works surprisingly well, adding extra
packages however can make the experience worse.

In other words, this package is not only an elaborate joke, but can be
used as test for your own packages hooking into Emacs' command loop,
be it by using `post-command-hook` or using timers for anything more
complex than keeping track of your oven.  If they behave as expected
with it enabled, chances are their handling of input is robust enough.

[image]: img/jammer.gif
[MELPA]: http://melpa.org/
[vim-molasses]: https://github.com/0x0dea/vim-molasses
[vim-hardtime]: https://github.com/takac/vim-hardtime
[hardmode]: https://github.com/wikitopian/hardmode
[annoying-arrows-mode]: https://github.com/magnars/annoying-arrows-mode.el
[hardcore-mode]: https://github.com/magnars/hardcore-mode.el
[guru-mode]: https://github.com/bbatsov/guru-mode
