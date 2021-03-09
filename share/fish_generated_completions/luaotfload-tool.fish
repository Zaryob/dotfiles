# luaotfload-tool
# Autogenerated from man page /usr/share/man/man1/luaotfload-tool.1.gz
complete -c luaotfload-tool -l update -s u --description 'Update the database; indexes new fonts.'
complete -c luaotfload-tool -l force -s f --description 'Force rebuilding of the database; re-indexes all fonts.'
complete -c luaotfload-tool -l local -s L --description 'Include font files in $PWD.'
complete -c luaotfload-tool -l no-reload -s n --description 'Suppress auto-updates to the database (e. g.'
complete -c luaotfload-tool -l no-compress -s c --description 'Do not filter the plain text version of the font index through gzip.'
complete -c luaotfload-tool -l prefer-texmf -s p --description 'Organize the file name database in a way so that it prefer fonts in the TEXMF…'
complete -c luaotfload-tool -l formats --description 'Extensions of the font files to index.'
complete -c luaotfload-tool -l find --description 'Resolve a font name; this looks up <name> in the database and prints the file…'
complete -c luaotfload-tool -l fuzzy -s F --description 'Show approximate matches to the file name if the lookup was unsuccessful (req…'
complete -c luaotfload-tool -l info -s i --description 'Display basic information to a resolved font file (requires --find).'
complete -c luaotfload-tool -l inspect -s I --description 'Display detailed information by loading the font and analyzing the font table…'
complete -c luaotfload-tool -l list --description 'Show entries, where CRITERION is one of the following: NDENT 7. 0.'
complete -c luaotfload-tool -l fields --description 'Comma-separated list of fields that should be printed.'
complete -c luaotfload-tool -l flush-lookups --description 'Clear font name lookup cache (experimental).'
complete -c luaotfload-tool -l cache --description 'Cache control, where DIRECTIVE is one of the following: NDENT 7. 0.'
complete -c luaotfload-tool -l show-blacklist -s b --description 'Show blacklisted files (not directories).'
complete -c luaotfload-tool -l dry-run -s D --description 'Donât load fonts when updating the database; scan directories only.'
complete -c luaotfload-tool -l no-strip --description 'Do not strip redundant information after building the database.'
complete -c luaotfload-tool -l max-fonts --description 'Process at most N font files, including fonts already indexed in the count.'
complete -c luaotfload-tool -l bisect --description 'Bisection of the font database.'
complete -c luaotfload-tool -l verbose -s v --description 'Set verbosity level to n or the number of repetitions of -v.'
complete -c luaotfload-tool -l quiet --description 'No verbose output (log level set to zero).'
complete -c luaotfload-tool -l log --description 'Redirect log output (for database troubleshooting), where CHANNEL can be NDEN…'
complete -c luaotfload-tool -l version -s V --description 'Show version numbers of components as well as some basic information and exit.'
complete -c luaotfload-tool -l help -s h --description 'Show help message and exit.'
complete -c luaotfload-tool -l diagnose --description 'Run the diagnostic procedure CHECK.  Available procedures are: NDENT 7. 0.'
complete -c luaotfload-tool -s '>' --description 'environment and kpse variables;.'
complete -c luaotfload-tool -l conf --description 'Read the configuration from FILE.  See luaotfload.'
complete -c luaotfload-tool -l dumpconf --description 'Print the currently active configuration; the output can be saved to a file a…'
complete -c luaotfload-tool -o ttc --description 'TrueType fonts and font collections; 2.  3.'

