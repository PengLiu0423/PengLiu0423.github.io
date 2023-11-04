---
title: "探究Golang之编译原理"
date: 2020-03-08T08:20:14+08:00
tags: ["Golang","编译原理"]
categories: ["Golang"]
comment: true
draft: true
toc: true
---
go语言是一门编译型语言，也就说代码需要编译成目标机器码才能在目标机器上运行。以下面demo.go为例，看看go语言编译器背后做了些什么事情。ttttt

```go
package main

import "fmt"

func main() {
	fmt.Println("hello world")
}
```

## 词法分析
词法分析是编译的第一步,它的作用是解析源文件,将文件中的字符串序列转换成Token序列。通常会把执行词法分析的程序称为词法解析器（lexer）,也叫扫描器（scanner）。

go语言的扫描器源代码位于`src/cmd/compile/internal/syntax`的`scanner`结构体,Token定义位于`src/cmd/compile/internal/syntax/tokens.go`。

通过源代码可以看到,词法分析主要是`scanner.next`方法驱动,主体是一个的switch case表示的状态机。在这个阶段,可以检测到单词拼写和非法字符错误。例如：~、@等符号，0x5j(16进制表示错误)

下面是demo.go被扫描的结果：

|位置|记号|  token | 注释 |
|:----:|:----:| :----: | :----: |
|1:1|package | _Package | 关键字 |
|1:9|main | _Name | 名称main |
|1:13||  _Semi | 分号 |
|3:1|import | _Import | 关键字 |
|3:8|"fmt"| _Literal | 字面量fmt |
|3:13||  _Semi | 分号 |
|5:1|func | _Func | 关键字 |
|5:6|main | _Name | 名称main |
|5:10|( | _Lparen | 左括号 |
|5:11|) | _Rparen | 右括号 |
|5:13|{| _Lbrace | 左大括号 |
|6:2|fmt | _Name | 名称fmt |
|6:5|. | _Dot | 点号 |
|6:6|Println| _Name | 名称Println |
|6:13|( | _Lparen | 左括号 |
|6:17|"hello world" | _Literal | 字面量hello world |
|6:27|) | _Rparen | 右括号 |
|6:28| | _Semi | 分号 |
|7:1|} | _Rbrace | 右大括号 |
|7:2|| _Semi | 分号 |

这个例子可以在`src/cmd/compile/internal/syntax/scanner_test.go`的`TestScanner`测试用例跑，可以看到最后生成的是带有行、列数字的Token序列。

## 语法分析
语法分析是编译的第二步，它的作用是将上一步生成的Token序列按给定的形式文法生成抽象语法树（AST）。通常用前后文无关文法或与之等价的Backus-Naur范式(BNF)将相应程序设计语言的文法准确的描述出来，go语言使用的是相应的变种EBNF。

go语言的语法分析器源代码位于`src/cmd/compile/internal/syntax`的`parser`结构体。在编译器入口的`src/cmd/compile/internal/gc`的main.go中，会调用`parseFiles`函数初始化`parser`结构体，对输入的所有文件进行词法与语法分析得到文件对应的抽象语法树。

语法分析的过程可以检测一些形式上的错误，例如：括号是否缺少一半，+ 号表达式缺少一个操作数等。

下面是demo.go语法分析的结果：

```
 	 0  *ast.File {
     1  .  Package: 1:1
     2  .  Name: *ast.Ident {
     3  .  .  NamePos: 1:9
     4  .  .  Name: "main"
     5  .  }
     6  .  Decls: []ast.Decl (len = 2) {
     7  .  .  0: *ast.GenDecl {
     8  .  .  .  TokPos: 3:1
     9  .  .  .  Tok: import
    10  .  .  .  Lparen: -
    11  .  .  .  Specs: []ast.Spec (len = 1) {
    12  .  .  .  .  0: *ast.ImportSpec {
    13  .  .  .  .  .  Path: *ast.BasicLit {
    14  .  .  .  .  .  .  ValuePos: 3:8
    15  .  .  .  .  .  .  Kind: STRING
    16  .  .  .  .  .  .  Value: "\"fmt\""
    17  .  .  .  .  .  }
    18  .  .  .  .  .  EndPos: -
    19  .  .  .  .  }
    20  .  .  .  }
    21  .  .  .  Rparen: -
    22  .  .  }
    23  .  .  1: *ast.FuncDecl {
    24  .  .  .  Name: *ast.Ident {
    25  .  .  .  .  NamePos: 5:6
    26  .  .  .  .  Name: "main"
    27  .  .  .  .  Obj: *ast.Object {
    28  .  .  .  .  .  Kind: func
    29  .  .  .  .  .  Name: "main"
    30  .  .  .  .  .  Decl: *(obj @ 23)
    31  .  .  .  .  }
    32  .  .  .  }
    33  .  .  .  Type: *ast.FuncType {
    34  .  .  .  .  Func: 5:1
    35  .  .  .  .  Params: *ast.FieldList {
    36  .  .  .  .  .  Opening: 5:10
    37  .  .  .  .  .  Closing: 5:11
    38  .  .  .  .  }
    39  .  .  .  }
    40  .  .  .  Body: *ast.BlockStmt {
    41  .  .  .  .  Lbrace: 5:13
    42  .  .  .  .  List: []ast.Stmt (len = 1) {
    43  .  .  .  .  .  0: *ast.ExprStmt {
    44  .  .  .  .  .  .  X: *ast.CallExpr {
    45  .  .  .  .  .  .  .  Fun: *ast.SelectorExpr {
    46  .  .  .  .  .  .  .  .  X: *ast.Ident {
    47  .  .  .  .  .  .  .  .  .  NamePos: 6:2
    48  .  .  .  .  .  .  .  .  .  Name: "fmt"
    49  .  .  .  .  .  .  .  .  }
    50  .  .  .  .  .  .  .  .  Sel: *ast.Ident {
    51  .  .  .  .  .  .  .  .  .  NamePos: 6:6
    52  .  .  .  .  .  .  .  .  .  Name: "Println"
    53  .  .  .  .  .  .  .  .  }
    54  .  .  .  .  .  .  .  }
    55  .  .  .  .  .  .  .  Lparen: 6:13
    56  .  .  .  .  .  .  .  Args: []ast.Expr (len = 1) {
    57  .  .  .  .  .  .  .  .  0: *ast.BasicLit {
    58  .  .  .  .  .  .  .  .  .  ValuePos: 6:14
    59  .  .  .  .  .  .  .  .  .  Kind: STRING
    60  .  .  .  .  .  .  .  .  .  Value: "\"hello world\""
    61  .  .  .  .  .  .  .  .  }
    62  .  .  .  .  .  .  .  }
    63  .  .  .  .  .  .  .  Ellipsis: -
    64  .  .  .  .  .  .  .  Rparen: 6:27
    65  .  .  .  .  .  .  }
    66  .  .  .  .  .  }
    67  .  .  .  .  }
    68  .  .  .  .  Rbrace: 7:1
    69  .  .  .  }
    70  .  .  }
    71  .  }
    72  .  Scope: *ast.Scope {
    73  .  .  Objects: map[string]*ast.Object (len = 1) {
    74  .  .  .  "main": *(obj @ 27)
    75  .  .  }
    76  .  }
    77  .  Imports: []*ast.ImportSpec (len = 1) {
    78  .  .  0: *(obj @ 12)
    79  .  }
    80  .  Unresolved: []*ast.Ident (len = 1) {
    81  .  .  0: *(obj @ 46)
    82  .  }
    83  }
```

* Package: 1:1代表Go解析出package这个Token在第一行的第一个
* main是一个ast.Ident标识符，它的位置在第一行的第9个
* 此处func main被解析成ast.FuncDecl（function declaration）,而函数的参数（Params）和函数体（Body）自然也在这个FuncDecl中。Params对应的是*ast.FieldList，顾名思义就是项列表；而由大括号“｛｝”组成的函数体对应的是ast.BlockStmt（block statement）
* 而对于main函数的函数体中，我们可以看到调用了println函数，在ast中对应的是ExprStmt（Express Statement），调用函数的表达式对应的是CallExpr(Call Expression)，调用的参数自然不能错过，因为参数只有字符串，所以go把它归为ast.BasicLis (a literal of basic type)。

## 语义分析

语义分析是Go编译的第三步，也被称为类型检查。在词法和语法分析之后，会得到每个文件对应的抽象语法树，类型检查会遍历语法树中的节点，对每个节点按照不同的情况进行如下的校验。这一阶段可以检测到类型的错误与不匹配。

1. 常量、类型和函数名及类型；
2. 变量的赋值和初始化；
3. 函数和闭包的主体；
4. 哈希键值对的类型；
5. 导入函数体；
6. 外部的声明；

在编译器入口的`src/cmd/compile/internal/gc`的main.go中，会调用`typecheck`进行类型检查。go语言的类型检查源代码位于`src/cmd/compile/internal/gc/typecheck.go`，最主要是是`typecheck`和`typecheck1`函数，`typecheck`主要作用就是判断编译器是否对当前节点执行过类型检查，同时做一些类型检查之前的准备工作。`typecheck1`是最核心的逻辑，这个函数由一个巨型的switch/case 构成，根据传入节点操作的不同，进入不同的 case 执行其中逻辑。
以一个case为例，分析下过程。
```go
    case OTARRAY:
		ok |= Etype
		r := typecheck(n.Right, Etype)
		if r.Type == nil {
			n.Type = nil
			return n
		}
```
这个分支首先会对右节点进行检查，即切片的元素类型。
```go
        if n.Left == nil {
			t = types.NewSlice(r.Type)
		} else if n.Left.Op == ODDD {
			if top&ctxCompLit == 0 {
				if !n.Diag() {
					n.SetDiag(true)
					yyerror("use of [...] array outside of array literal")
				}
				n.Type = nil
				return n
			}
			t = types.NewDDDArray(r.Type)
		} else {

            ...
            
		}
```
然后会根据左节点的不同，对Node进行操作，这三种形式：`[]int`,`[...]int`,`[3]int`。如果是第一种，会直接调用`NewSlice`返回一个`TSLICE`类型结构。如果是第二种，会调用`NewDDDArray`,返回一个需要推导的数组类型。最后如果源代码包含了数组大小，会调用`NewArray`返回一个`TARRAY`类型结构体。

## 中间代码生成
前面的词法分析、语法分析、语义分析属于编译器前端的内容，之后的阶段属于编译器后端。目标机器会有着各种各样的操作系统，不同的cpu类型，在生成机器码之前，会先生成用于抽象机器的代码，即中间代码。go语言使用的就是SSA特性的中间码(IR)，这种形式的中间码，最重要的一个特性就是最在使用变量之前总是定义变量，并且每个变量只分配一次。中间代码的生成过程就是抽象语法树到SSA中间代码的转成过程。

go语言中间代码转换位于`src/cmd/compile/internal/gc/ssa.go`中，主要逻辑根据当前的 CPU 架构初始化 SSA 配置 `ssaConfig`,注册runtime的方法，然后会对抽象语法树中节点的一些元素进行替换，比如将关键字`panic`转换为内置函数`gopanic`，`make`可以转成`makechan`、`makechan64`、`makemap`等等。转换后的函数可以在`src/cmd/compile/internal/gc/builtin/runtime.go`找到定义。这期间语法树会经过多轮的处理优化变成最后的SSA中间代码。在这个阶段主要优化是死码删除、逃逸分析、函数内联。

下面是demo.go的SSA中间代码，可以用`sudo GOSSAFUNC=main GOOS=linux GOARCH=amd64 go build demo.go`查看。
```
buildssa-enter
buildssa-body
. DCL l(6)
. . NAME-fmt.a a(true) l(273) x(0) class(PAUTO) esc(no) tc(1) assigned used SLICE-[]interface {}
 
. DCL l(6)
. . NAME-fmt.n a(true) l(273) x(0) class(PAUTO) esc(no) tc(1) assigned used int
 
. DCL l(6)
. . NAME-fmt.err a(true) l(273) x(0) class(PAUTO) esc(no) tc(1) assigned used error
 
. BLOCK-init
. . AS l(6) tc(1)
. . . NAME-main..autotmp_8 a(true) l(6) x(0) class(PAUTO) esc(N) tc(1) assigned used INTER-interface {}
. . . EFACE l(6) tc(1) INTER-interface {}
. . . . ADDR a(true) l(6) tc(1) PTR-*uint8
. . . . . NAME-type.string a(true) x(0) class(PEXTERN) tc(1) uint8
. . . . ADDR l(6) tc(1) PTR-*string
. . . . . NAME-main..stmp_0 a(true) l(6) x(0) class(PEXTERN) tc(1) addrtaken used string
. BLOCK l(6) hascall
. BLOCK-list
. . AS l(6) tc(1)
. . . NAME-main.~arg0 a(true) l(6) x(0) class(PAUTO) esc(no) tc(1) assigned used INTER-interface {}
. . . NAME-main..autotmp_8 a(true) l(6) x(0) class(PAUTO) esc(N) tc(1) assigned used INTER-interface {}
 
//...
 
. . AS l(6) tc(1)
. . . NAME-fmt.err a(true) l(273) x(0) class(PAUTO) esc(no) tc(1) assigned used error
. . . NAME-fmt..autotmp_4 a(true) l(274) x(0) class(PAUTO) esc(no) tc(1) assigned used error
 
. GOTO l(6) tc(1) main..i0
 
. LABEL l(6) tc(1) main..i0
buildssa-exit
```
## 机器码生成
机器码生成就是根据 SSA 中间代码生成机器码，这也是编译的最后一步了。在这个阶段中间代码被转化为汇编代码（Plan9），然后调用汇编器，汇编器会根据我们在执行编译时设置的架构，调用对应代码来生成目标机器码。这一过程会进行机器的相关优化、死码的进一步消除、合并指令和寄存器分配。

下面是demo.go的汇编代码，可以用` go tool compile -N -l -S demo.go`查看。
```
"".main STEXT size=147 args=0x0 locals=0x68
	0x0000 00000 (demo.go:5)	TEXT	"".main(SB), ABIInternal, $104-0
	0x0000 00000 (demo.go:5)	MOVQ	(TLS), CX
	0x0009 00009 (demo.go:5)	CMPQ	SP, 16(CX)
	0x000d 00013 (demo.go:5)	JLS	137
	0x000f 00015 (demo.go:5)	SUBQ	$104, SP
	0x0013 00019 (demo.go:5)	MOVQ	BP, 96(SP)
	0x0018 00024 (demo.go:5)	LEAQ	96(SP), BP
	0x001d 00029 (demo.go:5)	FUNCDATA	$0, gclocals·69c1753bd5f81501d95132d08af04464(SB)
	0x001d 00029 (demo.go:5)	FUNCDATA	$1, gclocals·86da00badb1a277fd4ad05aca8027ea8(SB)
	0x001d 00029 (demo.go:5)	FUNCDATA	$2, gclocals·bfec7e55b3f043d1941c093912808913(SB)
	0x001d 00029 (demo.go:5)	FUNCDATA	$3, "".main.stkobj(SB)
	0x001d 00029 (demo.go:6)	PCDATA	$0, $0
	0x001d 00029 (demo.go:6)	PCDATA	$1, $1
	0x001d 00029 (demo.go:6)	XORPS	X0, X0
	0x0020 00032 (demo.go:6)	MOVUPS	X0, ""..autotmp_0+56(SP)
	0x0025 00037 (demo.go:6)	PCDATA	$0, $1
  ...
```
## 参考
* [Introduction to the Go compiler](https://github.com/golang/go/tree/master/src/cmd/compile)
* [The Go Programming Language Specification](https://golang.org/ref/spec)
* [程序员的自我修养](https://book.douban.com/subject/3652388/)
* [1.1 概述· 浅谈Go 语言实现原理 - 面向信仰编程](https://draveness.me/golang/compile/golang-compile-intro.html)
