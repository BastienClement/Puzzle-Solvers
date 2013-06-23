Bimaru-Solver
=============

A simple Bimaru puzzle solver

Usage
-----

`lua bimaru.lua  <rows>  <cols>  [intructions...]  [boats...]  [opts...]`
	
- `<rows>` and `<cols>` are sequences of numbers describing how many ship cells should be on this row / col. The separator can be any non-numeric symbol.
- `[instructions...]` are used to initialize the board
	- Syntax: `<row>:<col>={what}`
	- `{what}` can be:
		- `w`, `W`, `~`: a water cell
		- `b`, `B`, `#`: a generic boat cell
		- `o`, `O`, `@`: a one-square boat (submarine)
		- `<`: the left-end of a boat
		- `>`: the right-end of a boat
		- `v`: the bottom-end of a boat
		- `^`: the top-end of a boat
- `[boats...]` define how many boats must be used for solving the board
	- Syntax: `<length>=<count>`
	- Examples:
		- `4=1`: You must have exactly 1 boat 4 squares long
		- `2=3`: You must have exactly 3 boats 2 squares long
- `[opts...]` change the solver behavior.
	- Available options:
		- `quick`: Aborts after the first solution is found.

Example input grid
------------------
```
 ------------------------------ 
|                   ~     ~    | 3
|                              | 2
|                              | 1
|                              | 2
|                              | 2
|                              | 0
|<#>                           | 1
|                              | 1
|                              | 7
|                              | 1
 ------------------------------ 
  4  0  2  1  2  0  5  0  5  1
```

Command line:
`lua bimaru.lua 3,2,1,2,2,0,1,1,7,1 4,0,2,1,2,0,5,0,5,1  1:7=w 1:9=w 7:1=o  1=4 2=3 3=2 4=1`
	
In this case, the board will contains the following boats:

- 4x `<#>`
- 3x `<# #>`
- 2x `<# # #>`
- 1x `<# # # #>`

Example output
--------------

```
galedric$ time luajit bimaru.lua 3,2,1,2,2,0,1,1,7,1 4,0,2,1,2,0,5,0,5,1 1:7=w 1:9=w 7:1=o 1=4 2=3 3=2 4=1 
Input grid:
 ------------------------------ 
|                   ~     ~    | 3
|                              | 2
|                              | 1
|                              | 2
|                              | 2
| ~                            | 0
|<#> ~                         | 1
| ~                            | 1
|                              | 7
|                              | 1
 ------------------------------ 
  4  0  2  1  2  0  5  0  5  1 

Pre-solving...
 ------------------------------ 
| #  ~ <#> ~ <#> ~  ~  ~  ~  ~ | 3
|    ~  ~  ~  ~  ~     ~  Λ  ~ | 2
| ~  ~  ~  ~  ~  ~  ~  ~  #  ~ | 1
|    ~  ~  ~  ~  ~     ~  #  ~ | 2
|    ~  ~  ~  ~  ~     ~  V  ~ | 2
| ~  ~  ~  ~  ~  ~  ~  ~  ~  ~ | 0
|<#> ~  ~  ~  ~  ~  ~  ~  ~  ~ | 1
| ~  ~  ~  ~  ~  ~  Λ  ~  ~  ~ | 1
| #  ~  <# # #>  ~  #  ~  <##> | 7
|    ~  ~  ~  ~  ~     ~  ~  ~ | 1
 ------------------------------ 
  4  0  2  1  2  0  5  0  5  1 

Solving...
 ------------------------------ 
| Λ  ~ <#> ~ <#> ~  ~  ~  ~  ~ | 3
| V  ~  ~  ~  ~  ~  ~  ~  Λ  ~ | 2
| ~  ~  ~  ~  ~  ~  ~  ~  #  ~ | 1
| ~  ~  ~  ~  ~  ~  Λ  ~  #  ~ | 2
| ~  ~  ~  ~  ~  ~  V  ~  V  ~ | 2
| ~  ~  ~  ~  ~  ~  ~  ~  ~  ~ | 0
|<#> ~  ~  ~  ~  ~  ~  ~  ~  ~ | 1
| ~  ~  ~  ~  ~  ~  Λ  ~  ~  ~ | 1
|<#> ~  <# # #>  ~  #  ~  <##> | 7
| ~  ~  ~  ~  ~  ~  V  ~  ~  ~ | 1
 ------------------------------ 
  4  0  2  1  2  0  5  0  5  1 

  4  <#> <#> <#> <#> 
  3  <##> <##> <##> 
  2  <###> <###> 
  1  <####> 

Found 1 solutions!
46 iterations

real	0m0.010s
user	0m0.005s
sys	0m0.003s
```
