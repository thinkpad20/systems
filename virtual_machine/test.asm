// Assembly file generated by my awesome VM compiler
// Input filename: test.txt
// 'push constant 3030' (line 0)
@3030
D=A
@SP
A=M
M=D
@SP
M=M+1
// 'pop pointer 0' (line 1)
@SP
AM=M-1
D=M
@THIS
M=D// 'push constant 3040' (line 2)
@3040
D=A
@SP
A=M
M=D
@SP
M=M+1
// 'pop pointer 1' (line 3)
@SP
AM=M-1
D=M
@THAT
M=D// 'push constant 32' (line 4)
@32
D=A
@SP
A=M
M=D
@SP
M=M+1
// 'pop this 2' (line 5)
@2
D=A
@THIS
D=M+D
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// 'push constant 46' (line 6)
@46
D=A
@SP
A=M
M=D
@SP
M=M+1
// 'pop that 6' (line 7)
@6
D=A
@THAT
D=M+D
@R13
M=D
@SP
AM=M-1
D=M
@R13
A=M
M=D
// 'push pointer 0' (line 8)
@THIS
D=M
@SP
A=M
M=D
@SP
M=M+1
// 'push pointer 1' (line 9)
@THAT
D=M
@SP
A=M
M=D
@SP
M=M+1
// 'add' (line 10)
@SP
AM=M-1
D=M
@SP
AM=M-1
M=M+D
@SP
M=M+1
// 'push this 2' (line 11)
@2
D=A
@THIS
A=M+D
D=M
@SP
A=M
M=D
@SP
M=M+1
// 'sub' (line 12)
@SP
AM=M-1
D=M
@SP
AM=M-1
M=M-D
@SP
M=M+1
// 'push that 6' (line 13)
@6
D=A
@THAT
A=M+D
D=M
@SP
A=M
M=D
@SP
M=M+1
// 'add' (line 14)
@SP
AM=M-1
D=M
@SP
AM=M-1
M=M+D
@SP
M=M+1
(END)
@END
0;JMP