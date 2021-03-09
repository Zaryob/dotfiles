# unix2mac
# Autogenerated from man page /usr/share/man/man1/unix2mac.1.gz
complete -c unix2mac -l allow-chown --description 'Allow file ownership change in old file mode.'
complete -c unix2mac -o ascii --description 'Convert only line breaks.  This is the default conversion mode.'
complete -c unix2mac -o iso --description 'Conversion between \\s-1DOS\\s0 and \\s-1ISO-8859-1\\s0 character set.'
complete -c unix2mac -o 1252 --description 'Use Windows code page 1252 (Western European).'
complete -c unix2mac -o 437 --description 'Use \\s-1DOS\\s0 code page 437 (\\s-1US\\s0).'
complete -c unix2mac -o 850 --description 'Use \\s-1DOS\\s0 code page 850 (Western European).'
complete -c unix2mac -o 860 --description 'Use \\s-1DOS\\s0 code page 860 (Portuguese).'
complete -c unix2mac -o 863 --description 'Use \\s-1DOS\\s0 code page 863 (French Canadian).'
complete -c unix2mac -o 865 --description 'Use \\s-1DOS\\s0 code page 865 (Nordic).'
complete -c unix2mac -s 7 --description 'Convert 8 bit characters to 7 bit space.'
complete -c unix2mac -s b -l keep-bom --description 'Keep Byte Order Mark (\\s-1BOM\\s0).'
complete -c unix2mac -s c -l convmode --description 'Set conversion mode.'
complete -c unix2mac -s D -l display-enc --description 'Set encoding of displayed text.'
complete -c unix2mac -s f -l force --description 'Force conversion of binary files.'
complete -c unix2mac -o gb -l gb18030 --description 'On Windows \\s-1UTF-16\\s0 files are by default converted to \\s-1UTF-8,\\s0 rega…'
complete -c unix2mac -s h -l help --description 'Display help and exit.'
complete -c unix2mac -s i -l info --description 'Display file information.  No conversion is done.'
complete -c unix2mac -s k -l keepdate --description 'Keep the date stamp of output file same as input file.'
complete -c unix2mac -s L -l license --description 'Display program\'s license.'
complete -c unix2mac -s l -l newline --description 'Add additional newline.'
complete -c unix2mac -s m -l add-bom --description 'Write a Byte Order Mark (\\s-1BOM\\s0) in the output file.'
complete -c unix2mac -s n -l newfile --description 'New file mode.'
complete -c unix2mac -l no-allow-chown --description 'Don\'t allow file ownership change in old file mode (default).'
complete -c unix2mac -s o -l oldfile --description 'Old file mode.  Convert file \\s-1FILE\\s0 and overwrite output to it.'
complete -c unix2mac -s q -l quiet --description 'Quiet mode.  Suppress all warnings and messages.  The return value is zero.'
complete -c unix2mac -s r -l remove-bom --description 'Remove Byte Order Mark (\\s-1BOM\\s0).'
complete -c unix2mac -s s -l safe --description 'Skip binary files (default).'
complete -c unix2mac -s u -l keep-utf16 --description 'Keep the original \\s-1UTF-16\\s0 encoding of the input file.'
complete -c unix2mac -o ul -l assume-utf16le --description 'Assume that the input file format is \\s-1UTF-16LE. \\s0 .'
complete -c unix2mac -o ub -l assume-utf16be --description 'Assume that the input file format is \\s-1UTF-16BE. \\s0 .'
complete -c unix2mac -s v -l verbose --description 'Display verbose messages.'
complete -c unix2mac -s F -l follow-symlink --description 'Follow symbolic links and convert the targets.'
complete -c unix2mac -s R -l replace-symlink --description 'Replace symbolic links with converted files (original target files remain unc…'
complete -c unix2mac -s S -l skip-symlink --description 'Keep symbolic links and targets unchanged (default).'

