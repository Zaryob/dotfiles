# formail
# Autogenerated from man page /usr/share/man/man1/formail.1.gz
complete -c formail -s v --description 'Formail will print its version number and exit.'
complete -c formail -s b --description 'Don\'t escape any bogus mailbox headers (i. e. , lines starting with `From \').'
complete -c formail -s p --description 'Define a different quotation prefix.   If unspecified it defaults to `>\'.'
complete -c formail -s Y --description 'Assume traditional Berkeley mailbox format, ignoring any  Content-Length: fie…'
complete -c formail -s c --description 'Concatenate continued fields in the header.'
complete -c formail -s z --description 'Ensure a whitespace exists between field name and content.'
complete -c formail -s f --description 'Force formail to simply pass along any non-mailbox format (i. e.'
complete -c formail -s r --description 'Generate an auto-reply header.'
complete -c formail -s k --description 'When generating the auto-reply header or when extracting fields, keep the bod…'
complete -c formail -s t --description 'Trust the sender to have used a valid return address in his header.'
complete -c formail -s s --description 'The input will be split up into separate mail messages, and piped into a prog…'
complete -c formail -s n --description 'Tell formail not to wait for every program to finish before starting the next…'
complete -c formail -s e --description 'Do not require empty lines to be preceding the header of a new message (i. e.'
complete -c formail -s d --description 'Tell formail that the messages it is supposed to split need not be in strict …'
complete -c formail -s l --description 'Generate a log summary in the same style as procmail.'
complete -c formail -s B --description 'Makes formail assume that it is splitting up a BABYL rmail file.'
complete -c formail -s m --description 'Allows you to specify the number of consecutive headerfields formail needs to…'
complete -c formail -s q --description 'Tells formail to (still detect but) be quiet about write errors, duplicate me…'
complete -c formail -s D --description 'Formail will detect if the Message-ID of the current message has already been…'
complete -c formail -s x --description 'Extract the contents of this  headerfield from the header.'
complete -c formail -s X --description 'Same as  -x , but also preserves/includes the field name.'
complete -c formail -s a --description 'Append a custom  headerfield onto the header; but only if a similar field doe…'
complete -c formail -s A --description 'Append a custom  headerfield onto the header in any case.'
complete -c formail -s i --description 'Same as  -A , except that any existing similar fields are renamed by prependi…'
complete -c formail -s I --description 'Same as  -i , except that any existing similar fields are simply removed.'
complete -c formail -s u --description 'Make the first occurrence of this field unique, and thus delete all subsequen…'
complete -c formail -s U --description 'Make the last occurrence of this field unique, and thus delete all preceding …'
complete -c formail -s R --description 'Renames all occurrences of the fieldname  oldfield into R newfield .'
complete -c formail -o q- --description '.'
complete -c formail -o total --description 'Output at most total messages while splitting.'

