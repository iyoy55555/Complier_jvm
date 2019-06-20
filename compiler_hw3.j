.class public compiler_hw3
.super java/lang/Object
.field public static x I = 20
.field public static f F = 3.5
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
.method static public pp()V
.limit stack 50
.limit locals 50
getstatic java/lang/System/out Ljava/io/PrintStream;
ldc "call pp"
invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V
	return
.end method
.method static public main([Ljava/lang/String;)V
.limit stack 50
.limit locals 50
	ldc 10.0
	fstore 0
	ldc 9
	istore 1
ldc 1
ldc 2.1
swap
i2f
fadd
	getstatic compiler_hw3/f F
fadd
putstatic compiler_hw3/f F
	getstatic compiler_hw3/f F
ldc 1.0
fsub
putstatic compiler_hw3/f F
Label_0 :
	iload 1
ldc 15
isub
ifgt Label_1
	iload 1
ldc 1
iadd
istore 1
	iload 1
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/println(I)V
goto Label_0
Label_1 :
	getstatic compiler_hw3/f F
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/println(F)V
	getstatic compiler_hw3/f F
	fload 0
fsub
f2i
ifle Label_2
getstatic java/lang/System/out Ljava/io/PrintStream;
ldc "f>d"
invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V
goto Label_3
Label_2 :
	getstatic compiler_hw3/x I
ldc 20
isub
ifne Label_4
	getstatic compiler_hw3/x I
ldc 15
isub
ifle Label_5
getstatic java/lang/System/out Ljava/io/PrintStream;
ldc "x>15"
invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V
goto Label_6
Label_5 :
getstatic java/lang/System/out Ljava/io/PrintStream;
ldc "x<15"
invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V
Label_6 :
goto Label_7
Label_4 :
	getstatic compiler_hw3/x I
	getstatic java/lang/System/out Ljava/io/PrintStream;
	swap
	invokevirtual java/io/PrintStream/println(I)V
Label_7 :
Label_3 :
invokestatic compiler_hw3/pp()V
	return
.end method
