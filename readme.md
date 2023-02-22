# Basic guide to my asm junk

Note that because I don't know for sure what address this program runs at,
be very careful with branching to fixed addresses. I found loading the
address into a register first and then branching with bx or blx to work.
There's probably a better way to fix that, like by not abusing .org as I am,
but I haven't fixed it yet.

Also see ptc_memory.s, which contains a bunch of useful addresses along
with the macros listed below.

## du_addr register, address
Use this to refer to PTC memory addresses. These will commonly be DUs or
contained within them. This macro performs the offset calculation for
you, so you don't need to remember the formula to get the current address of
any useful DU or whatever.

The correctly offset address is stored into the given register.

## asm_addr register, address
Use this to refer to program-local addresses. These will be labels you've
created within your program. This performs a similar adjustment to the above.
Theoretically this is what .org is supposed to be for, but that creates
too many empty bytes at the start of the file for some reason.

The adjusted address is stored into the given register.

## wide_str char[,char[,char...]]
A really stupid macro that adjusts a bunch of characters to match PTC's string
format, barely tested and not very easy to use. Not suggested for most uses,
but if you need a small string such as instruction name it works well enough.

