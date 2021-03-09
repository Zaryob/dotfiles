# nvme-set-feature
# Autogenerated from man page /usr/share/man/man1/nvme-set-feature.1.gz
complete -c nvme-set-feature -s n -l namespace-id --description 'Sets the feature for the given nsid.'
complete -c nvme-set-feature -s f -l feature-id --description 'The feature id to send with the command.  Value provided should be in hex.'
complete -c nvme-set-feature -s l -l data-len --description 'The data length for the buffer submitted for this feature.'
complete -c nvme-set-feature -s d -l data --description 'The data file for the buffer submitted for this feature.'
complete -c nvme-set-feature -s v -l value --description 'The value for command dword 11, the value you want to set the feature to.'
complete -c nvme-set-feature -s s -l save --description 'Save the attribute so that it persists through all power states and resets.'

