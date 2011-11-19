require_relative 'config.rb'

# Static variables
server = @user + "@" + @host
@date = `date +%Y%m%d-%H%M%S`.chomp
@sshCommand = nil
if (@usekey) then
	@sshCommand = ["ssh", "-i", @keylocation, server]
else
	@sshCommand = ["ssh", server]
end
