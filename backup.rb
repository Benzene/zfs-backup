#!/usr/bin/env ruby19

require_relative 'commons.rb'

if (ARGV.length == 1 && ARGV[0] == "--full") then
	puts "Forcing full backup of system."
	@fullBackup = true
else
	@fullBackup = false
end

puts "Initializing backup at " << @date

# Create the snapshots.
@snapshotlist = []

@fslist.each { |fs|
	snapshot = fs + "@" + @date
	print "Creating snapshot " << snapshot << "... "
	IO.popen(["zfs", "snapshot", snapshot, :err=>:close]) { |zfs_io|
		Process.wait zfs_io.pid
		if ($?.exitstatus == 0) then
			purefile = fs.gsub('/','_')
			@snapshotlist << { :fs => fs,
					:purefile => purefile,
					:file => @dist_path + purefile + '@' + @date,
					:date => @date,
					:snapshot => snapshot }
			puts "done."
		else
			puts "fail!"
		end
	}
}

# We have created a set of snapshots. 
# We want to send things incrementally, so we need the last stored snapshot.
if (@fullBackup) then
	@distsnaps = {}
else
	dist_ls = "ls " << @dist_path
	IO.popen(@sshCommand + [dist_ls], mode = "r") { |dist_io|
		distfiles = dist_io.readlines()

		# We read the files, taking advantage that they should (via ls)
		# be sorted from the oldest to the newest
		# Filesystems or snapshots with '@' will break everything. But they might
		# be forbidden by zfs anyway.
		@distsnaps = {}
		distfiles.each { |s|
			s2 = s.split('@')
			if (s2.size == 2) then
				@distsnaps[s2[0]] = s2[1].chomp
			elsif (s2.size == 3) then
				@distsnaps[s2[0]] = s2[1]
			end
		}
	}
end

# Serialize them and send them to the distant ssh server.
@snapshotlist.each { |snapshot|
	if (@distsnaps[snapshot[:purefile]] != nil) then
		puts "Newest existing snapshot for " + snapshot[:fs] + " is " + @distsnaps[snapshot[:purefile]]
		zfscmd = ["zfs", "send", "-i", @distsnaps[snapshot[:purefile]], snapshot[:snapshot]]
		print "Saving " << snapshot[:snapshot] << " to " << snapshot[:file] << "... "
		dist_cmd = "cat > " << snapshot[:file]
	else
		puts "No older existing snapshot for " + snapshot[:fs] + ". Sending full snapshot."
		zfscmd = ["zfs", "send", snapshot[:snapshot]]
		print "Saving " << snapshot[:snapshot] << " to " << snapshot[:file] << "@full... "
		dist_cmd = "cat > " << snapshot[:file] << '@full'
	end

	IO.popen(@sshCommand + [dist_cmd], mode="w") { |dist_io|
		IO.popen(zfscmd,"r") { |local_io|
			#tmp = local_io.read
			dist_io.write (local_io.read)
			#dist_io.write tmp
			dist_io.flush
			Process.wait local_io.pid
			if ($?.exitstatus == 0) then
				puts "done."
			else
				puts "fail!"
			end
		}
	}
}
