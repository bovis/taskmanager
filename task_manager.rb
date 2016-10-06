#file should first seek input from user to create a task
#I'm not sure I know how to delete line items yet
#
#for ch4, focus on:
# - use modules for repetitive information
# 	that can move between classes
# - figure out a way to pass a message to a method
# 	- use method_missing to verify method's existence
#
#for ch3, carryovers:
# - how to include a class method?
# 	- what would be overarching for tasks?
# - attr_* for instance variables
#
#for ch2, carryovers include:
# - use object_id built-in method
# - use required, optional, and default-valued arguments
# - include references from one variable to another, alter them sufficiently

class TaskElements
	def get_taskname
		puts "Enter the task you want to record."
		taskname = gets.chomp + " "
	end
	def get_currentdate
		require "date"
		currentdate = (DateTime.now).strftime("%Y-%m-%d %H:%M")
	end
end

class Actionlist
	attr_reader :tasklist, :userconfig
	def initialize(filename, userconfig)
		@filename = filename
		@userconfig = userconfig
	end

	def add
		write_check = Permissions.new("./tasklist", "./userconfig")
		write_check.new_file? if write_check.can_write?

		new_task = TaskElements.new
		to_add = new_task.get_taskname + new_task.get_currentdate

		open(@filename, "a") do |file|
			file.puts(to_add)
		end

		puts "Added '#{to_add}' to file name: #{@filename}."
		puts
		another_round = UserInterface.new
		another_round.run
	end

	def remove
		puts "Future consideration."
	end

	def list
		puts "User: "
		puts File.read(@userconfig)
		puts()
		puts "Your tasks are:"
		puts File.read(@filename)
		puts()

		another_round = UserInterface.new
		another_round.run
	end

	def update
		puts "Enter your name:"
		name = gets.chomp
		open(@userconfig, "w") do |file|
			file.puts(name)
		end
		puts "Added '#{name}' to user config in: #{@userconfig}."
		puts
		another_round = UserInterface.new
		another_round.run
	end
end

class Permissions
        attr_reader :filename, :userconfig, :path
	
	def initialize(filename, userconfig)
		@path = ENV['HOME']
                @filename = filename
                @userconfig = userconfig
        end

	def can_write?
		if File.stat(@path).writable? != true
			puts "Permission denied."
			exit
		end
	end

	def new_file?
		if File.file?(@filename) != true
			puts "File not found. Creating new."
			File.new(@filename, "w")
		else
		puts "File found."
		puts()
		end
	end
end

class UserInterface
	def run
		puts "What would you like to do?",
			"Options are 'list,' 'add,'",
			"and 'remove' tasks, 'update' user info, and 'exit' program."

		request = gets.downcase.chomp
		new_action = Actionlist.new("./tasklist", "./userconfig")

		if new_action.respond_to?(request)
			if request != "exit"
				new_action.send(request)
			else
				exit
			end
		else
			puts "That action is not available."
		end
	end
end

start = UserInterface.new
start.run
