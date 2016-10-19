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

	def list_shell_options
		puts "\nShell options are:",
		"> 'select' user",
		"> 'create' user",
		"> 'help' to show this menu",
		"> 'exit' program"
	end

	def list_user_options
		puts "\nUser options are:",
		"> 'list' your tasks",
		"> 'add' or 'remove' a task",
		"> 'drop' to shell, to change user"
	end
	
	def command
		puts  "-------------- "
		print "Choose a task: "
	end

	def header
		header = "Name\tDue Date\tDate Created\tGroup\tAge"
		puts header
		puts "+"*header.length
	end
end

module Color
	def color(foreground, background, text)
		"\e[#{foreground};#{background}m" + text + "\e[K\e[0m"
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
	include Prompts
	include Color

	def initialize(user)
		@path = ENV['HOME'] + "/.ruby-taskmanager/"
		@taskfile = @path + user + ".tasklist"
		@items = []
		@user = user
		@actions_allowed = ["add", "remove", "list", "help", "drop", "exit"] 
	end

	def shell
		while true
			print "#{@user}> "
			request = gets.chomp
			self.send(request) if @actions_allowed.include?(request)
		end
	end

	def add
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

	def list
		header

		count = 1
		IO.foreach(@taskfile) do |line|
			if count.odd?
				puts color(32, 40, "#{count}. #{line.strip}")
			else
				puts "#{count}. #{line.strip}"
			end
			count += 1
		end
	end

	def help
		list_user_options
	end

	def drop
		new = Shell.new
		new.shell
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
		@actions_allowed = ["select", "create", "help", "exit"]
	end
	
	def check_configs
		can_write?(@path, "No permission to write to #{@path}")
		#check config directory
		create_dir_if_missing(@path)
		#check if userlist file missing, create if empty
		create_file_if_missing(@userlist)
		create_user if File.size?(@userlist) == nil
	end

	def create
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

	def select 
		puts "\nSelect user (type name): "
		list_lines(@userlist)
		user = gets.chomp
		if list_include?(@userlist, user)
			session = User.new(user)
			session.shell
		else
			select
		end
	end

	def help
		list_shell_options
	end

	def exit
		abort
	end
	
	def shell
		while true
			print "shell> "
			request = gets.chomp
			self.send(request) if @actions_allowed.include?(request)
		end
	end
end

start = Shell.new
start.introduce
start.check_configs
start.shell
