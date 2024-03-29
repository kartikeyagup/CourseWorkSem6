	.text

/* Switch from current_thread to next_thread. Make next_thread
 * the current_thread, and set next_thread to 0.
 * Use eax as a temporary register, which should be caller saved.
 */
	.globl thread_switch
thread_switch:
	/* YOUR CODE HERE */
    movl current_thread, %eax
    pushal
    movl %esp, (%eax)
    movl next_thread, %ebx
    movl %ebx, current_thread
    movl (%ebx), %esp
    movl $0x0, next_thread
    popal
	ret				/* pop return address from stack */

