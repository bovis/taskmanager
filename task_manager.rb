#file should first seek input from user to create a task
#I'm not sure I know how to delete line items yet
#
#future concerns:
# - consider a persistent "add" state, to accept more than one item
# 	- maybe just an "add" syntax like "add [name] [due] [priority]"
#	- add could accept arguments
#		-but would need to change UI to accommodate args
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

class FileTransform
	def temp_and_replace(fullpath, content)
		File.open((fullpath + ".tmp"), "w+") do |file|
			file.puts(content)
		end

		#rename tmp file to original
		File.rename((fullpath + ".tmp"), fullpath)
	end
end

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
	attr_reader :tasklist, :userconfig
	def initialize(filename, userconfig)
		@path = ENV['HOME']
		@filename = filename
		@full_path = @path + @filename
		@userconfig = userconfig
		@@items = []
	end

	def add
		raise ArgumentError.new("No permission to write to #{@path}.") unless can_write?
		
		new_task = Task.new
		
		create_file_if_missing(@full_path)

		@@items = []
		IO.foreach(@full_path) do |line|
			@@items << line		
		end

		@@items << new_task.create_string
		
		new_transform = FileTransform.new
		new_transform.temp_and_replace(@full_path, @@items)
=begin
		#tmp file
		File.open((@full_path + ".tmp"), "w+") do |file|
			file.puts(@@items)
		end

		#rename tmp file to original
		File.rename((@full_path + ".tmp"), @full_path)
=end
	end

	def remove
		puts
		puts "Number of item to remove:"
		remove = gets.chomp

		IO.foreach(@full_path) do |line|
			@@items << line	
		end
		@@items.delete_at((remove.to_i) - 1)
		
		new_transform = FileTransform.new
		new_transform.temp_and_replace(@full_path, @@items)
=begin	
		File.open((@full_path + ".tmp"), "w+") do |file|
			file.puts(@@items)
		end

		#rename tmp file to original
		File.rename((@full_path + ".tmp"), @full_path)
=end
	end

	def list
		if File.exist?(@full_path)
			puts
			print "User: "
			IO.foreach(@userconfig) do |line|
				puts line
			end
			puts()
			#foreach better for larger files
			#wont load whole file into memory at once
			#overkill here, but good to learn
			count = 1
			puts "Your tasks are:"
			IO.foreach(@full_path) do |line|
				print count.to_s + ". "
				count += 1
				puts line
			end
		else
			puts "No tasks."
		end
	end

	def exit
		abort	
	end

	def update #for now, single line; overwrites previous listing
		IO.foreach(@userconfig) do |line|
			puts "Current username is: #{line}"
		end

		new_user = User.new
		new_user.grab_username

		new_transform = FileTransform.new
		new_transform.temp_and_replace(@userconfig, new_user.username)
=begin		
		File.open((@userconfig + ".tmp"), "w+") do |file|
			file.puts(new_user.username)
		end
		
		File.rename((@userconfig + ".tmp"), @userconfig)

		puts "Added '#{new_user.username}' to user config in: #{@userconfig}."
=end
	end
	
	private

	def can_write?
		File.stat(@path).writable?
	end

	def create_file_if_missing(path)
		File.new(path, "w+") if File.exist?(path) == false
	end

end

class UserInterface
	def introduce
		puts "WELCOME TO TASK MANAGER."
	end

	def list_options
		puts
		puts "Options are:"
		puts "> 'list' your tasks"
		puts "> 'add' a task"
		puts "> 'remove' the last entered task"
		puts "> 'update' user info"
		puts "> 'exit' program."
		puts  "-------------- "
		print "Choose a task: "
	end

	def process_option 
		@request = ""

		while @request
			@request = gets.downcase.chomp
			new_action = ActionList.new("/tasklist", "./userconfig")

			if new_action.respond_to?(@request)
					new_action.send(@request)
			else
				puts
				puts "ERROR: That action is not available."
			end

			puts  "-------------- "
			print "Choose a task: "
		end
	end
end

start = UserInterface.new
start.introduce
start.list_options
start.process_option
