Can be compiled with the dmd compiler:

dmd vm_trans.d

Usage:

vm_trans [-o filename.asm] [-noinit] [files]

If no output filename is specified, the program will default to the last filename in the list of files, with ".vm" replaced with ".asm". Note that if specifying a filename, the ".asm" must be entered by the user. The -noinit option omits the opening code which sets the stack pointer to 256 and calls Sys.init.

Example:
vm_trans -o FibonacciElement.asm Main.vm Sys.vm
vm_trans -o BasicLoop.asm -noinit BasicLoop.vm