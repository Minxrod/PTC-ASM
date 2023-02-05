# Basic guide to my asm junk

Also see ptc_memory.s, which contains a bunch of useful addresses along
with the silly macros listed below.

This should probably be included within that file, actually.

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
format, barely tested and not very easy to use. Only intended to be for
debugging because of how limited it is, but it's easier than manual string
conversion.
