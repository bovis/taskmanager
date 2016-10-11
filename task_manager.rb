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

require "date"
require_relative "stacklike"

class User
	attr_reader :username

	def grab_username
		puts
		puts "What is your username?"
		@username = gets.chomp
	end
end

class Task
	attr_reader :taskname

	def initialize
		@datetime = DateTime.now.strftime("%Y-%m-%d %H:%M")
	end
	
	def grab_taskname
		puts
		puts "What task would you like to enter?"
		@taskname = gets.chomp
	end

	def create_string
		"#{grab_taskname} #{@datetime}"
	end
end

class ActionList
	include Stacklike

	attr_reader :tasklist, :userconfig
	def initialize(filename, userconfig)
		@path = ENV['HOME']
		@filename = filename
		@userconfig = userconfig
	end

	def add
		raise ArgumentError.new("No permission to write to #{@path}.") unless can_write?
		
		new_task = Task.new
		#loop done on suggestion; investigate further implications
		#makes addition simpler; "a" creates new file when missing
		File.open((@path + @filename), "a") do |file|
			file.puts(new_task.create_string)
		end

		puts "Added new task, '#{new_task.taskname}'."
	end

	def remove
		puts "Future consideration."
=begin
		IO.foreach(@path + @filename) do |line|
			puts "Line is #{line}"
			add_to_stack(line)
		end
		remove_from_stack
=end
	end

	def list
		if File.exist?(@path + @filename)
			#read should be safe for reading single line
			puts "User: "
			puts File.read(@userconfig)
			puts()
			#foreach better for larger files
			#overkill for testing here, but good practice
			#	to learn
			count = 1
			puts "Your tasks are:"
			IO.foreach(@path + @filename) do |line|
				print count.to_s + ". "
				count += 1
				puts line
			end
			#puts File.read(@path + @filename)
		else
			puts "No tasks."
		end
	end

	def exit
		abort	
	end

	def update #for now, single line; overwrites previous listing
		new_user = User.new
		open(@userconfig, "w") do |file|
			file.puts(new_user.grab_username)
		end
		puts "Added '#{new_user.username}' to user config in: #{@userconfig}."
	end
	
	private

	def can_write?
		File.stat(@path).writable?
	end
end

class UserInterface
	def run
		@request = ""
		while @request != "exit"
			puts
			puts "What would you like to do? Options are:"
			puts "1. 'list' your tasks"
			puts "2. 'add' or 'remove' a task"
			puts "2. 'update' user info"
			puts "3. 'exit' program."

			@request = gets.downcase.chomp
			new_action = ActionList.new("/tasklist", "./userconfig")

			if new_action.respond_to?(@request)
					new_action.send(@request)
			else
				puts
				puts "ERROR: That action is not available."
			end
		end
	end
end

start = UserInterface.new
start.run
