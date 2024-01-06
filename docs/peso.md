Let's say that the keywords of a language, any language really, are merely keys to a hash table... and that the crux of a program meant to read this language, for any purpose, is to accurately map some textual input to the values contained within a table specific to that purpose.

In this sense, the lexing part of a language can be thought of as a data structure, or more accurately, a buffer with some labels; hashing is only a convenient method for calculating offsets into this buffer from textual input.

So here's a question: what if we ourselves define this table before invoking the reader? And better yet, what if we build our table from multiple ones?

The only requirement for this to work is fixed syntax -- or a *default* syntax that is subject to switches, that is, live overrides to syntactical rules.

For clarity, a "syntax rule" in this case is merely a check, or combination of checks, of whether some byte pattern is found within a block of memory, be it within an input buffer or some static region holding the reader's internal state.

To find patterns, that is, to perform checks, we must first point to one or more specific memory addresses. In order to differentiate between single values, strings of values and trees of strings, we shall define three levels:

- `l0`: fixed-size chunks.

- `l1`: variable-sized block of level zero memory.

- `l2`: variable-sized block of level one memory.

And to simplify our expressions, we shall use the following syntax:

- Blocks shall be referred to as `lX`, where `X` represents the level index.

- `lX-1` means one level lower, `lX+1` one level higher

- `X > 0` indicates block level one or two; `X < 2` is a block of level zero or one.

- If multiple blocks of the same level are used in the same expression, we shall label them `lX^A`, `lX^B`, `lX^C` and so on.

- `[lX^A,lX^B]` denotes a list of blocks, effectively `lX+1 if X < 2`.

- `lX^N` shall represent "last element", as in `[lX..lX^N]`.

- `Y` shall be used as index into such lists.

- `Y-1` means previous index; `Y+1` means next index.

- `Y++` means ascending search; `Y--` means descending.

- If multiple base indices are used, they will be labeled `Y^A`,`Y^B`, `Y^C` and so on.

- `lX[Y]` means `lX-1` within `lX if X > 0`.

- `lX[Y^A,Y^B,Y^C]` denotes a list of `lX-1` within `lX if X > 0`.

- Similarly, `lX[Y..Y+N]` is a linear range of `lX-1` within `lX if X > 0`.

- `xor`, `or`, `and`, `not`, etc. hold the same meaning as in common logic.

And to further narrow down the scope of what a rule may check for, we shall define the following operations:

- `eq`: `lX^A` is equal to `lX^B`.

- `at`: `lX eq lX+1[Y]`

- `seq`: ordered `[lX..lX^N] at lX+1[Y..Y+N]`.

- `useq`: unordered `[lX..lX^N] at lX+1[Y..Y+N]`.

- `ahead`: `lX^B at lX+1` __and__ `lX^A at lX+1 if Y++`.

- `tails`: `lX^B at lX+1` __and__ `lX^A at lX+1 if Y--`.

This is sufficient for basic analysis. For example, 

```$

A is l0 '$'
B is l0 '%'

C is l1 '%$'


pto C

if A not ahead B by 1
  ...

end if


```

Would look at a level one block and... (WIPWIPWIP DONT COMMIT)

- `is`: declare a block.

- `pto`: point to a given block.

- `by`: denote an offset for a search.
