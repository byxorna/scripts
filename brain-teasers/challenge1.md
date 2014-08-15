Math quiz
Input: standard input
Output: standard output

A popular game show has a segment where it gives its contestants a sequence of positive numbers and a target number.
The contestant must make a mathematical expression using all of the numbers in the sequence and only the operators: +, -, *, and, /.
Each number in the sequence must be used exactly once, but each operator may be used zero to many times.
The expression should be read from left to right, without regard for order of operations, to calculate the target number.
It is possible that no expression can generate the target number. It is possible that many expressions can generate the target number.

There are three restrictions on the composition of the mathematical expression:
*  the numbers in the expression must appear in the same order as they appear in the input file
*  since the target will always be an integer value (a positive number), 
   you are only allowed to use / in the expression when the result will give a remainder of zero.
*  you are only allowed to use an operator in the expression,
   if its result after applying that operator is an integer from (-32000 .. +32000).

Input
The input describes multiple test cases. The first line contains the number of test cases n.
Each subsequent line contains the number of positive numbers in the sequence p, followed by p positive numbers, followed by the target number. Note that 0 < p < 100. There may be duplicate numbers in the sequence. But all the numbers are less than 32000.

Output
The output should contain an expression, including all k numbers and (k-1) operators plus the equals sign and the target. Do not include spaces in your expression. Remember that order of operations does not apply here. If there is no expression possible output "NO EXPRESSION" (without the quotes). If more than one expression is possible, any one of them will do.
Sample Input
3
3 5 7 4 3
2 1 1 2000
5 12 2 5 1 2 4

Sample Output
5+7/4=3
NO EXPRESSION
12-2/5*1*2=4

Additional information / demands:
* We are mainly looking at your programming skills, but would also appreciate a solution that can handle the worst case number of positive numbers (99) in a test case.
* You can assume that the input is correctly formatted.
* We would like a solution that makes it easy to support more mathematical operators in the code.
---
