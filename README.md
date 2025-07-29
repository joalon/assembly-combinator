# Assembly combinators

A [Factorio](https://www.factorio.com) mod adding sophisticated combinators
that are programmed using a simple assembly dialect.

## Usage

Download it from the [mod portal](https://mods.factorio.com/mod/assembly-combinator).

### Example programs

A simple counter:
```
main:
    ADDI x10, x0, 0             # Initialize counter to 0
loop:
    ADDI x10, x10, 1            # Increment counter
    WSIG o1, copper-plate, x10   # Output counter value
    WAIT 60                     # Wait 1 second (60 game ticks)
    SLTI x6, x10, 100           # Check if counter < 100
    BNE  x6, x0, loop           # Branch if not equal to zero
    JAL  x1, main               # Jump back to main
```

## Contributions

PRs are welcome! Make sure to lint and test the code with [Busted](https://lunarmodules.github.io/busted). `busted test.lua`
