# zdb
# Autogenerated from man page /usr/share/man/man8/zdb.8.gz
complete -c zdb -s b --description 'Display statistics regarding the number, size logical, physical and allocated…'
complete -c zdb -s c --description 'Verify the checksum of all metadata blocks while printing block statistics se…'
complete -c zdb -s C --description 'Display information about the configuration.'
complete -c zdb -s d --description 'Display information about datasets.'
complete -c zdb -s D --description 'Display deduplication statistics, including the deduplication ratio dedup, co…'
complete -c zdb -o DD --description 'Display a histogram of deduplication statistics, showing the allocated physic…'
complete -c zdb -o DDD --description 'Display the statistics independently for each deduplication table.'
complete -c zdb -o DDDD --description 'Dump the contents of the deduplication tables describing duplicate blocks.'
complete -c zdb -o DDDDD --description 'Also dump the contents of the deduplication tables describing unique blocks.'
complete -c zdb -s E --description 'Decode and display block from an embedded block pointer specified by the word…'
complete -c zdb -s h --description 'Display pool history similar to zdb zpool Cm history, but include internal ch…'
complete -c zdb -s i --description 'Display information about intent log ZIL entries relating to each dataset.'
complete -c zdb -s k --description 'Examine the checkpointed state of the pool.'
complete -c zdb -s l --description 'Read the vdev labels and L2ARC header from the specified device.'
complete -c zdb -o ll --description 'In addition display label space usage stats.'
complete -c zdb -o lll --description 'Display every configuration, unique or not.'
complete -c zdb -s L --description 'Disable leak detection and the loading of space maps.'
complete -c zdb -s m --description 'Display the offset, spacemap, free space of each metaslab, all the log spacem…'
complete -c zdb -o mm --description 'Also display information about the on-disk free space histogram associated wi…'
complete -c zdb -o mmm --description 'Display the maximum contiguous free space, the in-core free space histogram, …'
complete -c zdb -o mmmm --description 'Display every spacemap record.'
complete -c zdb -s M --description 'Display the offset, spacemap, and free space of each metaslab.'
complete -c zdb -o MM --description 'Also display information about the maximum contiguous free space and the perc…'
complete -c zdb -o MMM --description 'Display every spacemap record.'
complete -c zdb -s O --description 'Look up the specified path inside of the dataset and display its metadata and…'
complete -c zdb -s s --description 'Report statistics on zdb zdb I/O.'
complete -c zdb -s S --description 'Simulate the effects of deduplication, constructing a DDT and then display th…'
complete -c zdb -s u --description 'Display the current uberblock.  El Pp Other options: -tag -width Ds.'
complete -c zdb -s A --description 'Do not abort should any assertion fail.'
complete -c zdb -o AA --description 'Enable panic recovery, certain errors which would otherwise be fatal are demo…'
complete -c zdb -o AAA --description 'Do not abort if asserts fail and also enable panic recovery.'
complete -c zdb -s e --description 'Operate on an exported pool, not present in /etc/zfs/zpool. cache.'
complete -c zdb -s x --description 'All blocks accessed will be copied to files in the specified directory.'
complete -c zdb -s F --description 'Attempt to make an unreadable pool readable by trying progressively older tra…'
complete -c zdb -s G --description 'Dump the contents of the zfs_dbgmsg buffer before exiting zdb.'
complete -c zdb -s I --description 'Limit the number of outstanding checksum I/Os to the specified value.'
complete -c zdb -s o --description 'Set the given global libzpool variable to the provided value.'
complete -c zdb -s P --description 'Print numbers in an unscaled form more amenable to parsing, eg.'
complete -c zdb -s t --description 'Specify the highest transaction to use when searching for uberblocks.'
complete -c zdb -s U --description 'Use a cache file other than /etc/zfs/zpool. cache.'
complete -c zdb -s v --description 'Enable verbosity.  Specify multiple times for increased verbosity.'
complete -c zdb -s V --description 'Attempt verbatim import.'
complete -c zdb -s X --description 'Attempt extreme transaction rewind, that is attempt the same recovery as F bu…'
complete -c zdb -s Y --description 'Attempt all possible combinations when reconstructing indirect split blocks.'
complete -c zdb -s y --description 'Perform validation for livelists that are being deleted.'

