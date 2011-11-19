# Configuration
@user = '' # Backup server user
@host = '' # Backup server host
@usekey = true # Whether to use an ssh private key. Recommended.
@keylocation = '' # Location of the ssh private key
@dist_path = '~/backup_dir/' #Location of the backup storage dir. Has to exist.
@fslist = ["tank/usr/home/wilya/fs1","tank/usr/home/wilya/fs2","tank/usr/home/wilya/fs3"]

@fsrestorelist = [ { :old => 'tank_usr_home_wilya_fs2', :new => 'tank/usr/home/wilya/fs22'} ]

@buffersize = 1024 * 1024 # Buffer size, in bytes.
