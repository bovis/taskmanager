require "date"

module Validation
	def temp_and_replace(path, content)
		File.open((path + ".tmp"), "w+") do |file|
			file.puts(content)
		end

		File.rename((path + ".tmp"), path)
	end
	
	def create_dir_if_missing(path)
		Dir.mkdir(path) if File.exist?(path) == false
	end

	def create_file_if_missing(path)
		File.new(path, "w+") if File.exist?(path) == false
	end

	def can_write?(path, error)
		raise ArgumentError.new(error) unless File.stat(path).writable?
	end
end

module List
	def list_lines(file, numbered=true)
		c = 1

		IO.foreach(file) do |line|
			if numbered
				puts c.to_s + ". " + line
				c += 1
			else
				puts line
			end
		end
	end

	def list_include?(file, item)
		array = []
		IO.foreach(file) do |line|
			array << line.chomp
		end

		array.include?(item)
	end
end

module Prompts
	def introduce
		puts "WELCOME TO TASK MANAGER."
	end

	def list_options
		puts "\nOptions are:",
		"> 'list' your tasks",
		"> 'add' or 'remove' a task",
		"> 'create' a new user",
		"> 'switch' users",
		"> 'exit' program."
	end

	def command
		puts  "-------------- "
		print "Choose a task: "
	end
end

class Task
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

class User
	include Validation 

	def initialize(user)
		@path = ENV['HOME'] + "/.ruby-taskmanager/"
		@taskfile = @path + user + ".tasklist"
		@items = []
		@user = user
	end

	def add
		can_write?(@path, "No permission to write to #{@path}")

		new_task = Task.new
		
		@items = []
		IO.foreach(@taskfile) do |line|
			@items << line		
		end

		@items << new_task.create_string
		
		temp_and_replace(@taskfile, @items)
	end

	def remove
		self.list

		@items = []
		puts "\nNumber of item to remove:"
		remove = gets.chomp

		IO.foreach(@taskfile) do |line|
			@items << line
		end
		@items.delete_at((remove.to_i) - 1)
		
		temp_and_replace(@taskfile, @items)

		list
	end

	def color(foreground, background, text)
		"\e[#{foreground}m\e[#{background}m" + text + "\e[0m"
	end

	def list
		print "\nUser: #{@user}"
		count = 1
		@items = []
		puts "\nYour tasks are:"
		IO.foreach(@taskfile) do |line|
			if count.odd?
				puts (color(32, 40, count.to_s + ". ") + color(32, 40, line))
			else
				puts (count.to_s + ". " + line)
			end
			count += 1
		end
	end

	def exit
		abort	
	end
end

class Shell
	include Validation
	include Prompts
	include List

	def initialize
		@path = ENV['HOME'] + "/.ruby-taskmanager/"
		@userlist = @path + "userlist"
		@items = []
	end
	
	def check_configs
		#check config directory
		create_dir_if_missing(@path)
		#check if userlist file missing, create if empty
		create_file_if_missing(@userlist)
		create_user if File.size?(@userlist) == nil
	end

	def create_user
		puts "Enter your username: "
		user = gets.chomp
		@items = []
		@items << user

		IO.foreach(@userlist) do |line|
			@items.unshift(line)
		end

		temp_and_replace(@userlist, @items)
		create_file_if_missing(@path + user + ".tasklist")
	end

	def start_user_session 
		puts "\nSelect user (type name): "
		list_lines(@userlist)
		user = gets.chomp
		if list_include?(@userlist, user)
			@session = User.new(user)
		else
			start_user_session
		end
	end
	
	def process_option 
		while true
			request = gets.downcase.chomp
			#new_action = User.new(choose_user)

			#break apart this if series into objects
			if request == "switch"
				start_user_session
			elsif request == "create"
				create_user
			elsif @session.respond_to?(request)
				@session.send(request)
			else
				puts "\nERROR: That action is not available."
			end

			command
		end
	end
end

start = Shell.new
start.introduce
start.check_configs
start.start_user_session
start.list_options
start.process_option
