# pesign-client
# Autogenerated from man page /usr/share/man/man1/pesign-client.1.gz
complete -c pesign-client -l unlock --description 'Unlock the specified token.'
complete -c pesign-client -l pinfd --description 'When using --unlock, read the token\'s PIN from the open file descriptor pinfd.'
complete -c pesign-client -l pinfile --description 'When using --unlock, read the token\'s PIN from the file pinfile.'
complete -c pesign-client -l sign --description 'br Sign the binary specified by infile.'
complete -c pesign-client -l export --description 'When used with --sign, write the signature to outfile.'
complete -c pesign-client -l infile --description 'When used with --sign, specify the input binary.'
complete -c pesign-client -l outfile --description 'When used with --sign, specify output file.'
complete -c pesign-client -l token --description 'When used with --unlock or --sign, use the specified NSS token\'s certificate …'
complete -c pesign-client -l certificate --description 'When used with --sign, use the certificate database entry with the specified …'
complete -c pesign-client -l is-unlocked --description 'Query a token specified with --token for lock status.'
complete -c pesign-client -l kill --description '.'

