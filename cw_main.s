/*                           HANGMAN                            */ 
/*                                                              */
/*                  @author: Martin Teoharov                    */ 
/*                    @student_id: *******                      */ 
/*                                                              */
/*                                                              */
/*                VIM COMMANDS TO REDUCE FILE SIZE              */
/*                                                              */
/*                  :g/^$/d   removes empty lines               */
@                   :g/\*/d   removes commented lines           @
/*                                                              */
/*                                                              */
/*                          DESCRIPTION                         */
/*   Armv6                                                       */
/*                                                              */
/*   This file appears quite large due to excessive             */
/*   documentation/explanation, spacing for better              */
/*   readability, etc. A couple of vim commands are provided    */
/*   above to make it easier to shrink.                         */
/*                                                              */
/*   Every subroutine has a description above it defining       */
/*   it's arguments, return type, etc.                          */
/*   The arguments are generally specified in registers         */
/*   r1 through r3 and return values are in register r0.        */
/*                                                              */
/*   Most subroutines' names' end in either _as or _c.          */
/*   This is to specify if a subroutine makes use               */
/*   of any C functions or is entirely written in assembly.     */
/*                                                              */
/*   The "brain" of the game lies in the main subroutine which  */
/*   is also marked as the entry. It contains the               */
/*   game_loop that calls all of the helper functions defined   */
/*   above it. Reading the code from there will make            */
/*   it easier to understand.                                   */
/*                                                              */

.global main                           @ mark this as the entry

/*
 *  
 * contains_as searches a string specified in r1 for a letter
 * specified in r2. Returns values [0, 1] in r0 signifying if
 * there has been a miss or a hit respectively.
 *
 */ 

@ returns[1]:   r0: [0 It Doesn't Contain, 1 - It Contains]
@ arguments[2]: r1: [String Addr to Search], r2: [Letter Addr]
contains_as: @{
    push {r1-r6, lr}

    /* INPUT IS OKAY, STORE LETTER IN GUESSED_LETTERS */
    bl length_as                  @ r0 now contains length of string

    ldrb r4, [r2]
    mov r5, #0

    mov r6, #0
    loop_letters:
        add r5, r5, #1
        ldrb r3, [r1], #1
        cmp r3, r4
        moveq r6, #1

        cmp r5, r0
        blt loop_letters

    mov r0, r6

    pop {r1-r6, lr}
    bx lr
@}


/*
 *  
 * mod_as takes the modulo specified in r2, and applies it to the number
 * specified in r1. Returns the result in r0
 *
 * The single line comments in the subroutine give a specific example
 * on how the function works.
 * 
 */ 

@ returns[1]:   r0: [Number % Modulo]
@ arguments[2]: r1: [Number], r2: [Modulo]
mod_as: @{
    push {r1-r4, lr}

    mov r0, r1                 @ number to operate on
    mov r1, r2                 @ modulo

    @ e.g Number = 127; Modulo = 10
    udiv r3, r0, r1            @ 127 / 10    = 12
    mul r4, r3, r1             @ 12  * 10    = 120
    sub r3, r0, r4             @ 127 - 120   = 7
    mov r0, r3                 @ Number % Modulo
    
    pop {r1-r4, lr}
    bx lr
@}


/*
 *
 * rand_c makes use of C functions to output a random number that can take values
 * from 0 to 32767 (size of signed 16bit int)
 *
 */ 

@ returns[1]:   r0: [Random Number]
@ arguments[1]: r1: [RNG range]
rand_c: @{
    push {r1, lr}

    mov r0, #0
    mov r1, #0
    bl time                      @ Gets the Current System Time To Use As a Seed for Srand
    bl srand                     
    bl rand                      @ Rand Num is Now in r0

    pop {r1, lr}
    bx lr
@}


/*
 *
 * length_as counts the number of chars in a string specified in r1 before
 * it reaches a NULL (#0) byte.
 *
 */ 
@ returns[1]:   r0: [Word Length]
@ arguments[1]: r1: [Word Address]
length_as: @{
    push {r1, r2, lr}
    mov r0, #0
    loop:
        ldrb r2, [r1], #1
        cmp r2, #0
        addne r0, r0, #1
        bne loop
    pop {r1, r2, lr}
    bx lr
@}

/*
 *
 * append_as adds a char specified in r2 to a string specified in r1.
 * Makes use of length_as in order to append the char in the very end of the string.
 *
 */ 
@ returns[0]:   void
@ arguments[1]: r1: [Word Address], r2: [Letter Address]
append_as: @{
    push {r0-r2, lr}

    bl length_as            @ operates on r1 and returns length in r0

    ldrb r2, [r2]
    strb r2, [r1, r0]

    pop {r0-r2, lr}
    bx lr
@}


/*
 *
 * print_hang_state prints the current hang state which is passed in r1.
 * Depending on what state it is on - it writes to the console a different string.
 * 
 */ 
@ returns [0]:   void
@ arguments [1]: r1: [Hang State]
print_hang_state: @{
    push {r1, lr}

    /* IF CASE N THEN GENERAL_PROMPT(N) */
    cmp r1, #1                          @ 
    ldreq r1, =hang_first
    cmp r1, #2
    ldreq r1, =hang_second
    cmp r1, #3
    ldreq r1, =hang_third
    cmp r1, #4
    ldreq r1, =hang_fourth
    cmp r1, #5
    ldreq r1, =hang_fifth
    cmp r1, #6
    ldreq r1, =hang_sixth
    cmp r1, #7
    ldreq r1, =hang_seventh

    bl general_prompt	

    pop {r1, lr}
    bx lr
@}

/*
 * general_prompt writes a message specified in r1 to the console.
 * It is used whenever there isn't any specific task following the output 
 * (for example reading from keyboard) and as such it returns void.
 */ 

@ returns[0]:   void
@ arguments[1]: r1: [Message]
general_prompt: @{
    push {r0-r4, lr}
    
    bl length_as
    mov r2, r0
    
    /* WRITE PROMPT */
    mov r0, #1                              @ stdout
    @r1                                     @ prompt
    @r2                                     @ lendth of prompt
    mov r7, #4                              @ service call: write
    svc 0                                   
    
    pop {r0-r4, lr}
    bx lr
@}

/*
 * Empties letter buffer
 */ 
@ returns[0]:   void
@ arguments[1]: r1: [buffer to empty]
empty_buffer: @{
    push {r0-r2, lr}

    /* EMPTY THE LETTER VARIABLE FROM A PREVIOUS ROUND */
    @ldr r1, =buffer
    bl length_as                           @ returns length in r0

    loop_null:
        sub r0, r0, #1                     @ remove from length untill it reaches 0
        ldrb r2, [r1]
        mov r2, #0
        strb r2, [r1], #1
        cmp r0, #0
        bgt loop_null

    pop {r0-r2, lr}
    bx lr
@}

/*
 * Called at the end of the game to ask the user if he/she
 * wants to continue playing or exit the game.
 * 
 * If the user wants to start over this subroutine will also 
 * help clean all the core buffers that the game uses.
 *  
 * By default any input that is invalid will be interpreted
 * as "exit the game". This is signified with a capital "N"
 * and lowercase "y" in the "prompt_user_exit" string. 
 * If either capital "Y" or lowercase "y" is entered -
 * the game will start over.
 */ 
@ returns[1]:   r0: [0 - wants to exit, 1 - wants to start over]
@ arguments[0]: void
exit_prompt: @{
    push {r1, lr}

    ldr r1, =letter
    bl empty_buffer

    ldr r1, =prompt_user_exit
    bl general_prompt

    /* READ FROM KEYBOARD */
    mov r0, #0                                @ stdin keyboard
    ldr r1, =letter                           @ address of buffer to store in
    mov r2, #30                               @ max length of input
    mov r7, #3                                @ service call: read
    svc 0                                     @ execute service call

    mov r0, #0                                @ By default set not to start over [0 - dont start over, 1 - start over]

    /* COMPARE IF INPUT EQUALS Y || y */
    ldrb r2, [r1]
    cmp r2, #89                              @ if uppercase Y
    moveq r0, #1 
    cmp r2, #121                             @ if lowercase y
    moveq r0, #1 

	cmp r0, #0
	beq exit_game
     
    /* IF GAME STARTS OVER THEN EMPTY ALL BUFFERS */
    ldr r1, =buffer
    bl empty_buffer
    ldr r1, =word        
    bl empty_buffer
    ldr r1, =misses         
    bl empty_buffer
    ldr r1, =letter         
    bl empty_buffer
    ldr r1, =word_responsive
    bl empty_buffer
    ldr r1, =guessed_letters
    bl empty_buffer

    exit_game:
    pop {r1, lr}
    bx lr
@}


/*
 * guess_prompt prompts the user to enter his/her guess 
 * and stores it in the letter buffer.
 */ 
@ returns[0]:   void
@ arguments[1]: r1: [Correct Word Location]
guess_prompt: @{
    push {r1-r5, lr}

    prompt_start:

    mov r4, r1                                @ move correct word location to r4

    ldr r1, =letter
    bl empty_buffer

    /* PROMPT USER TO GUESS THE WORD */
    ldr r1, =prompt_guess_string              @ addr of prompt
    bl general_prompt

    /* READ FROM KEYBOARD */
    mov r0, #0                                @ stdin keyboard
    ldr r1, =letter                           @ address of buffer to store in
    mov r2, #30                               @ max length of input
    mov r7, #3                                @ service call: read
    svc 0                                     @ execute service call

    pop {r1-r5, lr}
    bx lr
@}

/* 
 * Checks for invalid input/zero(0). Returns and integer
 * value representing the state.
 *
 * It also performs the conversion of lowercase letters
 * to uppercase & searches the guessed_letters buffer
 *
 * arguments: void
 * returns: r0:  [ 0: exit the game,
 *     		       1: valid,
 *                 2: less chars
 *                 3: more chars,
 *   			   4: invalid char,
 *                 5: char is guessed already ]
 */

guess_validity_check: @{
    push {r1-r5, lr}

    mov r6, #1                     @ valid by default

    /* CHECK IF INPUT IS LOWERCASE AND IF SO MAKE IT UPPER CASE */
	ldr r2, =letter
	ldrb r3, [r2]
    cmp r3, #122
    bgt continue                   @ use this to avoid the case when first line is GE and last line executes because of that
    cmple r3, #97
    subge r3, r3, #32              @ 'a' - 'A' = 32
    strb r3, [r2]                  @ store back to letter
    continue:

    /* CHECK NUMBER OF CHARS */
    ldr r1, =letter
    bl length_as
    sub r0, r0, #1
    cmp r0, #1
    movlt r6, #2
    movgt r6, #3
	bne exit

    /* CHECK IF INPUT = ![a-zA-Z] */
	ldr r2, =letter
	ldrb r3, [r2]
	cmp r3, #48                        @ user has inputted a zero "0" so we exit the game
	moveq r6, #0
	beq exit

    cmp r3, #90
    movgt r6, #4
	bgt exit
    cmp r3, #65
    movlt r6, #4
	blt exit
    
    /* SEARCH AGAINST ALREADY GUESSED LETTERS */
    ldr r1, =guessed_letters
    ldr r2, =letter
    bl contains_as
    cmp r0, #1
    moveq r6, #5
    ldreq r1, =error_guessed_letter
    bleq general_prompt
	beq exit

	exit:
	cmp r6, #2
    ldreq r1, =error_has_less
    bleq general_prompt

	cmp r6, #3
    ldreq r1, =error_has_more
    bleq general_prompt

	cmp r6, #4
    ldreq r1, =error_invalid_char
    bleq general_prompt
    
    mov r0, r6

    pop {r1-r5, lr}
    bx lr
@}

/*
 * guess_process processes the guess stored in the letter buffer.
 * It first saves it to the already guessed letters buffer, then 
 * checks if it is correct or wrong and returns 1 or 0 respectively. 
 * Finally it checks if all of the word has been guessed and if
 * this is the case it returns 2.
 */ 
@ returns[1]: r0: [0: incorrect, 1: guess is correct, 2: word is all guessed]
@ arguments[0]: void
guess_process: @{
    push {r1-r7, lr}

    /* STORE LETTER IN GUESSED LETTERS */
    ldr r1, =guessed_letters
    ldr r2, =letter
    bl append_as

    /* CHECK GUESS */
    ldr r1, =word_responsive
	bl length_as                 @ stores length in r0
	ldr r2, =letter
	ldrb r2, [r2]
      
	ldr r3, =word

	mov r5, #0                   @ counter
	mov r6, #0                   @ boolean that returns state of guess: 0 wrong, 1 right, 2 word is fully guessed
    mov r7, #1                   @ boolean that checks if the word is fully guessed

    loop_length:

		ldrb r4, [r3, r5]
		cmp r2, r4
		streqb r4, [r1, r5]
        moveq r6, #1

        /* CHECK IF THERE IS A UNDERSCORE CHARACTER IN THE RESPONSIVE WORD */
        ldrb r4, [r1, r5]
        cmp r4, #95              @ check if character is underscore
        moveq r7, #0

		add r5, r5, #1           @ increase the count

		cmp r5, r0
        blt loop_length

    mov r0, r6                   @ return boolean that checks if guess is correct

    cmp r7, #1                   @ if there are no underscores - the word is correct
    moveq r0, #2

    pop {r1-r7, lr}
    bx lr
    
@}

/*
 * load_responsive_word creates the so called "responsive_word" which contains underscores 
 * based on the length of the word which is passed in r1
 * 
 */ 
@ returns[0]:   void
@ arguments[1]: r1: [Length]
load_responsive_word: @{
    push {r0-r5, lr}

    ldr r2, =word_responsive
    mov r3, r1 @ backup length
    mov r4, #0

    loop_len:
        mov r0, #95             @ ascii code #95 is "_"
        strb r0, [r2, r4]
        add r4, r4, #1

        sub r1, r1, #1

        cmp r1, #0
        bgt loop_len
    
    pop {r0-r5, lr}
    bx lr
    
@}

/*
 * load_rand_word loads a random word from a file located
 * in "guess_words_loc".
 * 
 */ 
@ returns[0]: void
@ arguments[0]: void
load_rand_word: @{
    push {r0-r5, lr}

    /* OPEN (CREATE) FILE */
    ldr r0, =guess_words_loc  @ store addr of guess_words_loc in r0

    /* SETUP PERMISSIONS & DESCRIPTORS */
    mov r1, #0x42              @ Create for Reading & Writing
    mov r2, #384               @ Read & Write Permissions for Owner
    mov r7, #5                 @ Syscall (5) Open/Create
    svc 0

    /* READ FROM FILE */
    ldr r1, =buffer            @ addr of buffer
    mov r2, #300               @ maximum length of input
    mov r7, #3                 @ service call: read
    svc 0                     

    /* PICK RANDOM NUM */
    bl rand_c                 @ stores num in r0

    mov r1, r0
    mov r2, #10
    bl mod_as                 @ stores num in r0

    /* GET SPECIFIC LINE OF FILE */
    ldr r1, =buffer
    ldr r3, =word
    mov r2, #0
    mov r5, r0                 @ number of line we want to get
    mov r6, r5
    add r6, #1

    loop_file:
        ldrb r0, [r1]          @ load a single byte 
        ldrb r4, [r3]          @ load a single byte 

        cmp r2, r6             @ check if we have passed the 
        beq finish             @ line we want to record

        strb r0, [r1], #1      @ store next char in buffer
        
        cmp r2, r5
        streqb r0, [r3], #1    @ store chars only if on correct line

        cmp r0, #10
        addeq r2, r2, #1       @ a line has passed

        b loop_file

    finish:

    pop {r0-r5, lr}
    bx lr
@}

main:@{
    push {r0-r8, lr}

    ldr r1, =prompt_hangman_title
    bl general_prompt

    /* WELCOME USER && LOAD A RANDOM WORD FROM FILE */
    ldr r1, =prompt_welcome_string
    bl general_prompt               @ welcomes the user
    bl load_rand_word               @ stores chosen line in .word

    /* GENERATE RESPONSIVE WORD */
    ldr r1, =word                   @ to be passed to length_as
    bl length_as                    @ stores length in r0
    mov r1, r0
    sub r1, r1, #1                  @ remove one from the length
    bl load_responsive_word         @ generates underscores equal to length in r0 and stores it in .word_responsive

    /* PRINT FIRST HANG_STATE */
    mov r1, #1                      @ error counter
    bl print_hang_state

    /* PRINT RESPONSIVE WORD & MISSES */
    ldr r1, =word_responsive_appearance
    bl general_prompt
    ldr r1, =word_responsive
    bl general_prompt
    ldr r1, =misses_appearance
    bl general_prompt
    ldr r1, =misses
    bl general_prompt

    mov r2, #1                      @ set up error counter

    /* BEGIN GAME LOOP */
    game_loop: 
        /* PROMPT USER TO GUESS */
        bl guess_prompt

        /* CHECK FOR BASIC VALIDITY OF INPUT [a-zA-Z] */
        bl guess_validity_check     @ returns: r0 [0: exit the game, 1: input is valid, 2: less chars, 3: more chars]
		cmp r0, #0                   
		beq force_quit              @ if user has entered "0" then quit
        cmp r0, #1
        bgt game_loop               @ if invalid, start over.

        /* CHECK IF GUESS HAS BEEN CORRENT OR INCORRECT */
        bl guess_process            @ returns: r0 [0: incorrect, 1: guess is correct].

        cmp r0, #0
        addeq r2, r2, #1            @ if guess is incorrect add a mistake to the error counter.

        /* IF STATE: GUESS IS INCORRECT */
        push {r1}
        mov r1, r2
        bl print_hang_state         @ always print_hang_state - looks much better, but before submission uncomment above line
        pop {r1}

        /* IF STATE: GUESS IS INCORRECT */
        push {r1, r2}
        cmp r0, #0
        ldreq r1, =misses
        ldreq r2, =letter
        bleq append_as
        pop {r1, r2}
        
        /* IF STATE: WIN */
        cmp r0, #2
        ldreq r3, =prompt_win_string
        beq quit
    
        /* PRINT RESPONSIVE WORD & MISSES */
        ldr r1, =word_responsive_appearance
        bl general_prompt
        ldr r1, =word_responsive
        bl general_prompt
        ldr r1, =misses_appearance
        bl general_prompt
        ldr r1, =misses
        bl general_prompt

        /* IF FINAL STATE IS REACHED & PLAYER HAS LOST */
        cmp r2, #7
        ldreq r3, =prompt_loss_string
        bleq quit

        b game_loop
    quit:

    /* PRINTS LOSS/WIN & REVEALS THE WORD */
    mov r1, r3
    bl general_prompt
    ldr r1, =prompt_word_was
    bl general_prompt
    ldr r1, =word
    bl general_prompt

    /* PROMPTS USER TO PLAY AGAIN */
    bl exit_prompt
    cmp r0, #1
    bleq main

	force_quit:
    pop {r0-r8, lr}

    mov r7, #1                               @ exit
    svc #0
@}

.bss

    /* CORE BUFFERS */
    buffer:         	            .space 200
    .align 2
    word:                           .space 20
	.align 2
    misses:                         .space 20
	.align 2
    letter:                         .space 20
	.align 2
    word_responsive:                .space 20
	.align 2
    guessed_letters:                .space 20
	.align 2

.data

    /* FILE LOCATION STRING */
    guess_words_loc:                .asciz "words"
    .align 2
    word_responsive_appearance:     .asciz "\nWord: "
    .align 2
    misses_appearance:              .asciz "\n\nMisses: "
    .align 2

    /* PROMPT STRINGS*/
    prompt_welcome_string:          .asciz "Let's play a game of hangman!\nAuthor: Martin Teoharov \n"
    .align 2
    prompt_guess_string:            .asciz "\n\n\nEnter the next character (A-Z), or 0 (zero) to exit: "
    .align 2
    prompt_win_string:              .asciz "                                 __ \n  __ __            _ _ _ _       |  |\n |  |  |___ _ _   | | | |_|___   |  |\n |_   _| . | | |  | | | | |   |  |__|\n   |_| |___|___|  |_ _ _|_|_|_|  |__| \n\n\n\n"
    .align 2
    prompt_loss_string:             .asciz "                       __ \n  __ __            _                |  |\n |  |  |___ _ _   | |   ___  __  _  |  |\n |_   _| . | | |  | |_ | . ||__'|_  |__|\n   |_| |___|___|  |___||___|,__||_  |__|\n\n\n\n"
    .align 2
    prompt_word_was:                .asciz "Your word was: "
    .align 2
    prompt_user_exit:               .asciz "Would you like to play again? [y/N]: "
    .align 2
    prompt_hangman_title:           .asciz "\n  _  \n | | \n | |__   __ _ _ __   __ _ _ __ ___   __ _ _ __ \n | '_ \\ / _` | `_ \\ /  ` | '_  `_ \\ / _` | '_ \\ \n | | | | (_| | | | | (_| | | | | | | (_| | | | |    \n |_| |_|\\__,_|_| |_|\\__, |_| |_| |_|\\__,_|_| |_| \n                     __/ |\n                    |___/\n \n"
    .align 2

    /* ERROR STRINGS*/
    error_has_less:                 .asciz "Error: Input one letter at a time please\n"
    .align 2
    error_has_more:                 .asciz "Error: Stop cheating! Too many letters. Input one letter at a time\n"
    .align 2
    error_guessed_letter:           .asciz "Error: You have guessed this letter already. Try another one.\n"
    .align 2
    error_invalid_char:             .asciz "Error: Input is invalid char\n"
    .align 2

    /* HANG STATES */
    hang_first:                     .asciz  " \n +---+\n |   |\n |    \n |    \n |    \n |    \n ======\n\n "
    .align 2
    hang_second:                    .asciz  " \n +---+\n |   |\n |   0\n |    \n |    \n |    \n ======\n\n "
    .align 2
    hang_third:                     .asciz  " \n +---+\n |   |\n |   0\n |   |\n |    \n |    \n ======\n\n "
    .align 2
    hang_fourth:                    .asciz  " \n +---+\n |   |\n |   0\n |  /|\n |    \n |    \n ======\n\n "
    .align 2
    hang_fifth:                     .asciz  " \n +---+\n |   |\n |   0\n |  /|\\\n |    \n |    \n ======\n\n "
    .align 2
    hang_sixth:                     .asciz  " \n +---+\n |   |\n |   0\n |  /|\\\n |  / \n |    \n ======\n\n "
    .align 2
    hang_seventh:                   .asciz  " \n +---+\n |   |\n |   0\n |  /|\\\n |  / \\\n |    \n ======\n\n "
    .align 2
