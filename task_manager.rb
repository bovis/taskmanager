#file should first seek input from user to create a task
#I'm not sure I know how to delete line items yet
#
#for ch3, include:
# ** use class to contain list, add, remove
# ** above can be instance methods
# - how to include a class method?
# 	- what would be overarching for tasks?
# 	- do I still need any object methods?
# - attr_* for instance variables
# ** constant may be used for default filename?
# ** any way to use inheritance?
#
#for ch2, carryovers include:
# - use object_id built-in method
# - use required, optional, and default-valued arguments
# - include references from one variable to another, alter them sufficiently
class Environment
	require 'date'

	FILEDIR = ENV['HOME']	#or rel to user home

	TASKFILE = "/tasklist"
	WRITETASK = FILEDIR + TASKFILE

	USERFILE = "/userinfo"
	WRITEUSER = FILEDIR + USERFILE

	current_time = DateTime.now
	DATETIME = current_time.strftime("%Y-%m-%d %H:%M")
end

class User_attr
	def initialize
		attr_accessor :name
	end
end

class Operations
	def add
		write_check = Permissions.new
		write_check.new_file? if write_check.can_write?

		print "What is the name and date of the ",
		"task you want to record?"
		puts()
		new_task = gets.chomp + " #{Environment::DATETIME}"

		open(Environment::WRITETASK, "a") do |file|
			file.puts(new_task)
		end

		puts "Added '#{new_task}' to file name: #{Environment::WRITETASK}."
	end

	def remove
		puts "Future consideration."
	end

	def list
		puts "User: "
		puts File.read(Environment::WRITEUSER)
		puts()
		puts "Your tasks are:"
		puts File.read(Environment::WRITETASK)
	end

	def update
		puts "Enter your name:"
		name = gets.chomp
		open(Environment::WRITEUSER, "w") do |file|
			file.puts(name)
		end
		puts "Added '#{name}' to user config in: #{Environment::WRITEUSER}."
	end

end

class Permissions
	def can_write?
		if File.stat(Environment::FILEDIR).writable? != true
			puts "Permission denied."
			exit
		end
	end

	def new_file?
		if File.file?(Environment::WRITEPATH) != true
			puts "File not found. Creating new."
			File.new(WRITEPATH, "w")
		else
		puts "File found."
		puts()
		end
	end
end

class Entrance
	def desired_action
		puts "What would you like to do?",
			"Options are 'list,' 'add,'",
			"and 'remove' tasks or 'update' user info."

		action = gets.downcase.chomp
		new_action = Operations.new

		if new_action.respond_to?(action)
			new_action.send(action)
		else
			puts "That action is not available."
		end
	end
end

start = Entrance.new
start.desired_action
