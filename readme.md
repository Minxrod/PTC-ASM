# PTC epic ASM hacking

This is an attempt at creating some sort of resource to make writing and 
testing ASM slightly easier. If you use this, PLEASE offer usability feedback.

# Dependencies

* PTCTools - get that from here: https://github.com/Minxrod/PTCTools
Set the environment variable PTCTOOLS to point to the main file `ptctools.py`.

* GNU ARM assembler, install that from somewhere.
I think the following will work for Debian/probably some derivatives:
```
sudo apt install binutils-arm-none-eabi
```

I only tested this in bash, I don't know if it works in other shells.

# Building

`./build asm.s ASMGRP [PROGRAM]`

If no arguments are provided, will create the loader _ASMLOAD only.

If assembly source is provided with no GRP name, will assemble and not remove
the output files.

If assembly source and GRP are provided, will assemble and encode result into
a GRP file with the given name.

If all arguments are provided, will additionally build a second program. 
(This is useful for writing programs that test the _ASMLOAD program.)

# Writing

WARNING: You don't know for sure what DU addresses will be when running
your program. Additionally, be very careful with branching to fixed addresses.
I found loading the address into a register first and then branching 
with bx or blx to work. There's probably a better way to fix that, like by not
abusing .org as I am, but I haven't fixed it yet.

WARNING: If you clear or destroy the data in GRP0, your program WILL crash.
Be very careful not to use ACLS, or GCLS on the page containing your code. 

See peekpoke.s for an example program that uses each of these macros.
You can build with `./build peekpoke.s ASM_MEM VRAMPOKE`

Also see ptc_memory.s, which contains some of the useful addresses along
with the macros listed below.

WARNING: You must have called `calcOffsetAddress` for du_addr and asm\_addr to
work correctly!

## du_addr register, address

Use this to refer to PTC data addresses. These will commonly be DUs or
contained within them. This macro performs the offset calculation for
you, so you don't need to remember the formula to get the current address of
any useful DU or whatever.

The correctly offset address is stored into the given register.

## asm_addr register, address
Use this to refer to program-local addresses. These will be labels you've
created within your program. This performs a similar adjustment to the above.
Theoretically this is what .org is supposed to be for, but that creates
too many empty bytes at the start of the file if I set it to the real address.

The adjusted address is stored into the given register.

## wide_str char[,char[,char...]]
A really stupid macro that adjusts a bunch of characters to match PTC's string
format. Not suggested for most uses, but if you need a tiny alphabet string
such as an instruction name it works well enough.

# Resources

You may find some of these to be helpful.

PTC specific information:
* https://petitcomputer.fandom.com/wiki/User_blog:Minxrod/More_memory_research
* https://petitcomputer.fandom.com/wiki/User_blog:Minxrod/Some_function_notes

ARM reference:
* https://documentation-service.arm.com/static/5ea68b849931941038ded96e

NDS/DSi reference:
* https://www.problemkaputt.de/gbatek.htm

Inspired by this:
* https://github.com/zoogie/petit-compwner

