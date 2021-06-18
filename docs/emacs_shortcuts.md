	C-f     Move forward a character
        C-b     Move backward a character

        M-f     Move forward a word
        M-b     Move backward a word

        C-n     Move to next line
        C-p     Move to previous line

        C-a     Move to beginning of line
        C-e     Move to end of line

        M-a     Move back to beginning of sentence
        M-e     Move forward to end of sentence

        M-<     Start of Buffer
        M->     End of Buffer

        C-u <x> command repeating command x times C-g Quit

        C-h k command helps for commands
	<DEL> Delete the character just before the cursor
	C-d Delete the next character after the cursor

        M-<DEL> Kill the word immediately before the cursor
	M-d Kill the next word after the cursor

        C-<SPACE> Marking mode
                <UP> / <DOWN>       Mark area moving lines
                C-<UP> / C-<DOWN>   Mark area moving text group (like paragraph)
		C-x C-x             Change marker up to down or down to up


        C-k Kill from the cursor position to end of line
	M-k Kill to the end of the current sentence C-<SPACE> Set Mark

        C-w           You need to move cursow and when you pushed that you will kill text
	M-w	      Copy text

        C-y           Paste latest killed text.
        C-y M-y       Paste killed test if you keep moving with M-y you see older killed texts.

        C-x u
        C-/           Undo latest operation
        C-_

        C-x C-f       Find file

        C-x C-b       List Of buffers
        C-x s         Save some buffers
	C-x k	      Kill buffer
        C-x 1         Show just one window
        C-x b <FNAME> Goes back FNAME file

        C-x           Character eXtend
        M-x           Name command eXtend

        M-x repl s<Return>changed<Return>altered<Return>
        M-x recover-this-file<Return>


        M-x autofill-mode
        C-x f <x>               This fils paragraphs in <x> chars
        M-q

        C-s             Search throught diretly
        C-r             Search throught reversed way

        C-x 2           Splits window into to
        C-x o           Goes other window
        C-M-v           Moves other window cursor one page down.

	F10 or M-`      Open toolbar

	C-x i           İnsert file into default buffer

	M-{ 		Move backward one paragraph.
	M-}		Move forward one paragraph.

	C-x [		Move backward one paragraph.
	C-x ] 		Move forward one paragraph.


	C-x C-x 	Changes marking direction

	M-u 		Uppercase all chars
	M-c 		Capitalize startings
	M-l		Downcase all chars

	C-t		Transpose two chars
	M-t		Transpose two words
	C-x C-t		Transpose two lines

	M-x revert-buffer	  Reopens file and revert not shaved changes

	M-% 		Search first given variable and set query as change with second one
		!	Replace All Query
		Del	Not change-just move other
		n	Not change-just move other
		.	Replace current instance and quit
		Space	Move other instance. When reach the end, it will stop
		y	Move other instance. When reach the end, it will stop
		^	Move back instance. When reach the start, it won't stop

		Enter   Quit from query
		q	Quit from query

		C-r	Recursively Edit (Mütüş özellik)


	C-x 5 		Frame works
	    C-x 5 2	Open a new frame
	    C-x 5 0	Delete current frame
	    C-x 5 o	Switch to other frame
	    C-x 5 f	Open file on other frame
	    C-x 5 r	Make frame read only
	    C-x 5 b	Make a frame and display other frame on it

	C-x b	  	change buffer
	C-x C-b		Buffer window.
	    d 		Mark buffer to delete.
	    k 		Mark buffer to delete.
	    s		Mark save stat for buffer.
	    m		Mark buffer displayed in window.
	    ~		Mark buffer as unmodified.
	    u		unmark buffer's sets.
	    x 		Proceed buffers mark.
	    v		Display buffers marked.
	    o 		Replace other window with this buffer.
	    f 		Replace buffer list with this buffer.
	    %		Toggle readonly status for buffer.
	    1		Display buffer in full screen.
	    2		Display buffer and the next one in horizontal windows.
	    q 		quit buffet list

	C-x C-q		Read-only mode buffer

	C-x 2 		Create a new window down of screen vertically
	C-x 3		Create a new windows right of screen horizontal
	C-x 0		Kill window.

	C-x 4 f		Find a new file from other window
	C-x 4 b		Find a buffer for other window
	C-u C-x ^	Make vertical windows taller

	C-u C-x }	Make horizontal window larger
	C-u C-x {	Make horizontal window smaller

	C-x +		Resize all windows symmetrically.
	C-x - 		Shrink window if larger than buffer.

	C-x r m		       Create a book mark it needs a name. It is filename as default
	C-x r b 	       Jump to a book mark
	C-x r l		       Opens list of book marks as window
	    f 		       Goes buffer that in current line
	    j		       Goes buffer that in current line
	    Enter	       Goes buffer that in current line
	    C-o		       Open bookmark in another window
	    o		       Open bookmark in another window
	    d		       Flag bookmark for deletion
	    Ctrl-d	       Flag bookmark for deletion
	    k		       Flag bookmark for deletion
	    u		       Deflag bookmarks
	    x		       Process bookmarks
	    r		       Rename bookmark
	    s		       Save all bookmarks listed
	    m		       Mark bookmarks to be displayed in miultiple windows
	    v 		       Display marked bookmarks or the one the cursor is on if none are marked
	    t 		       Toggle display of paths to files assoc. with bookmarks
	    w		       In the minibuffer, display location of file assoc. with bookmark
	    Del		       Remove mark from bookmark on previous line if it is marked, or not marked move to previous line
	    A 		       Display annotation for current bookmark.
	    e		       Edit or create annotation for current bookmark
	    	   C-c C-c     Close and save annotation window

	M-x bookmark-rename    Renames bookmark
	M-x bookmark-delete    Deletes bookmark



	M-!		       Run a command

	M-h M-|		       Runs shell command on given region
	C-u M-! <command>      Runs command and result will be put in file.
	M-x shell	       Opens shell mode

	    M-p		       Retrieves last command.
	    M-n 	       Retrieves next command
	    C-c C-o	       Removes last commands output.
	    C-c C-r	       Goes start of last commands output.
	    C-c C-p	       Goes previous command line group
	    C-c C-n	       Goes next command line group


	C-x C-f <dir name>     Open directory as dired mod
	C-x d	     	       Start dired mode
	    A		       Search files
	    B		       Byte compile file
	    C		       Copy file
	    D		       Query for deletition
	    e		       edit file
	    g		       Reread the directory
	    G 		       Change group permissions
	    H		       Create a hard link to this file.
	    i		       Add a subdir
	    k		       Remove line from buffer.Not deletes directories.
	    L		       Load file
	    M		       Use chmod and change mods
	    o		       Find file in another window, move there.
	    O		       Change ownership of file
	    P 		       Print file.
	    Q		       Query replace string in marked files.
	    R		       Rename file
	    S		       Create a symbolic link to this file.
	    s		       Sort the Dired display by date or by filename
	    t		       Toggle marks on files.
	    y		       Display information on the type of file. (file command like information)
	    v		       View file (read-only)
	    Z		       Comptrdd or uncompress file.

	    d		       Flag for deletion.
	    m		       Mark with *
	    u		       Remove mark
	    x		       Run operations on marks.

	    !		       Ask for open a shell
	    +		       Create a directory
	    >		       Move to next directory
	    <		       Move to previous directory

	M-x lpr-buffer	       Print file in buffer.
	M-x lpr-region	       Print selected text in buffer.


	M-x man <command>      Displaying man file for command

	M-x calendar	       Display calendar
	    C-f		       Move next day
	    C-b		       Move previous day
	    M-}		       Move next month
	    M-{		       Move previous month
	    C-x [	       Move next year
	    C-x ] 	       Move previous year
	    C-v		       Forward three mounts later
	    M-v		       Back three months

	    a		       	    	  List holidays for current month
	    M-x list-calendar-holidays	  List holidays for current month

	    i d		       Insert diary entry for day
	    i w		       Insert diary entry for week
	    p d		       Display date of this year
	    p o		       Display date with different calendars
	    x 		       Mark important days in calendar
	    u 		       Unmark
	    h		       List holidays
	    i d		       Add an entry for current day
	    i w		       Add an weeklu entry based on the they
	    i y		       Add annual entry
	    i c		       Add an enrty to recur every n days.
	    i b		       Add an block entry
	    s 		       Display diary file
	    C-space	       Mark regions by time rather than horizontally
	    M-=		       Count the number of days in a region
	    q 		       Quit


