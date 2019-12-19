# aarch64issue

This repository is a minimal sample which demonstrates how an issue effecting bare metal Rust code complied with aarch64-unknown-none and aarch64-unknown-none-softfloat targets. It might also be useful as a guide to learning how to debug bare metal programs using qemu.

Code compiled for aarch64-unknown-none-softfloat works. Code compiled with aarch64-unknown-none seems to lock at the instruction `dup   v0.16b, w1`. 


## Replication

**Notes:** 

- Requires docker to be installed. Uses [https://hub.docker.com/r/andrerichter/raspi3-utils](https://hub.docker.com/r/andrerichter/raspi3-utils) crate to provide qemu. 
- Requires gdb-multiarch to be installed. 
- Opens port localhost:1234. Debug on port localhost:1234.
- QEMU is opened in stopped state and will need to be started using gdb `si` (step instruction) or `continue` command.

**In a terminal run:**

```
>$ make objdump_none qemu_none
...
qemu-system-aarch64 -s -S -M raspi3 -kernel kernel8.img -serial stdio
VNC server running on 127.0.0.1:5900
...
```

**In another terminal run gdb-multiarch session:**

```
>$ gdb-multiarch 
...
(gdb) target remote localhost:1234
Remote debugging using localhost:1234
warning: No executable has been specified and target does not support
determining executable automatically.  Try using the "file" command.
0x0000000000000000 in ?? ()
(gdb) layout asm
(gdb) si
(gdb) continue
...
```

Code will halt at this instruction:

```
>│0x804f8 dup    v0.16b, w1 
```

Typing ctrl+c will break execution.

```
0x00000000000804f8 in ?? ()

Thread 1 received signal SIGINT, Interrupt.
0x0000000000000200 in ?? ()
(gdb) kill
Kill the program being debugged? (y or n) y
[Inferior 1 (process 1) killed]
(gdb)

```

After break, execution is at location 0x200. Likely an exception occurred but because no exception table is set up in the code execution has effectively halted.

## Synopsis

According to [the arm docs](http://infocenter.arm.com/help/topic/com.arm.doc.dui0802b/DUP_advsimd_elt_vector.html) the operation `dup   v0.16b, w1` is a SIMD instruction for use with the core's floating point functionality.

According to this post on the [rpi baremetal forums](https://www.raspberrypi.org/forums/viewtopic.php?f=72&t=249588&p=1527796&hilit=FPU#p1527796) the following magic code should work to enable the FPU:

```
.section ".text.fpu"
.global __enable_fpu
__enable_fpu:
    mrc     p15, 0, r0, c1, c0, 2
    orr     r0, r0, #0x300000        /* enable single precision */
    orr     r0, r0, #0xC00000        /* enable double precision */
    mcr     p15, 0, r0, c1, c0, 2
    mov     r0, #0x40000000          /*FPU enable bit only applies to AARCH32 */
    fmxr    fpexc, r0
```

When complied for the aarch64 target the `mrc` and other operands aren't recognized. In addition various ARM resources seem to indicate that this applies to AARCH32 code or AARCH32 running in an AARCH64 context.



## Makefile Targets:

### softfloat:

Build target with aarch64-unknown-none-softfloat and put results in ./kernel8 and ./kernel8.img respectively.

### none:

Build target with aarch64-unknown-none and put results in ./kernel8 and ./kernel8.img respectively.

### softfloat_debug:

Build debug target with aarch64-unknown-none-softfloat and put results in ./kernel8 and ./kernel8.img respectively.

### none_debug:

Build debug target with aarch64-unknown-none and put results in ./kernel8 and ./kernel8.img respectively.


### qemu_none: / qemu_softfloat:

Build `none` or `softfloat` then use [https://hub.docker.com/r/andrerichter/raspi3-utils](https://hub.docker.com/r/andrerichter/raspi3-utils) crate to run in qemu. 

**Notes:** Requires docker to be installed. Requires gdb-multiarch to be installed. Debug on port localhost:1234. QEMU is started in stopped state and will need to be started using gdb `continue` command.


### objdump_none: / objdump_softfloat:

Dump disassembly listing into file `none.lst` or `softfloat.lst` respectively.

### clean:

Clean and remove all files.

## Credit

This code contains software copyright "Andre Richter <andre.o.richter@gmail.com>".
