# Assembly combinators

A [Factorio](https://www.factorio.com) mod adding sophisticated combinators
that are programmed using a simple assembly dialect.

## Usage

Download it from the [mod portal](https://mods.factorio.com/mod/assembly-combinator).

### Example programs

A simple counter:

```
main:
    ADDI x10, x0, 0              # Initialize counter to 0
loop:
    ADDI x10, x10, 1             # Increment counter
    WSIG o1, copper-plate, x10   # Output counter value
    WAIT 60                      # Wait 1 second (60 game ticks)
    SLTI x6, x10, 100            # Check if counter < 100
    BNE  x6, x0, loop            # Branch if not equal to zero
    JAL  x1, main                # Jump back to main
```

Reading an input signal:

```
main:
    RSIG x10, iron-plate           # x10 = red + green count of iron-plate (default 'both')
    RSIG x11, iron-plate, red      # x11 = red wire count only
    SLTI x6, x10, 100              # x6 = 1 if x10 < 100, else 0
    BNE  x6, x0, low               # branch to 'low' if iron-plate is scarce
    WSIG o1, copper-plate, x10     # otherwise mirror count to copper-plate output
    JAL  x0, main
low:
    WSIG o1, iron-plate, x10       # signal scarcity by switching the output item
    JAL  x0, main
```

`RSIG` reads the count of a named item signal from the combinator's input
circuit network into a general-purpose register. The optional third argument
selects the wire (`red`, `green`, or `both`); omitting it is equivalent to
`both`, which sums the red and green counts. Missing signals read as 0.

## Contributions

PRs are welcome! Make sure to lint and test the code with [luacheck](https://github.com/mpeterv/luacheck) and [Busted](https://lunarmodules.github.io/busted). `busted test.lua`
