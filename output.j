.class public compiler_hw3
.super java/lang/Object
.field public static x I = 10
.field public static f F
.method static public foo(II)F
.limit stack 50
.limit locals 50
	iload 0
	iload 1
iadd
	i2f
	fstore 2
	fload 2
	freturn
.end method
.method static public main([Ljava/lang/String;)V
.limit stack 50
.limit locals 50
	ldc "Hello"
	astore 0
ldc 5
ldc 4
idiv
	getstatic compiler_hw3/f F
swap
i2f
fmul
	f2i
	istore 1
	getstatic compiler_hw3/x I
	iload 1
invokestatic compiler_hw3/foo(II)F
ldc 3
i2f
fadd
	f2i
	istore 2
	getstatic compiler_hw3/f F
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/println(F)V
	return
.end method
