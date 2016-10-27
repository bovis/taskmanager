require "date"
require "csv"

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

module Color
	def color(foreground, background, text)
		#will extend color to end of row in terminal
		"\e[#{foreground};#{background}m" + text + "\e[K\e[0m"
	end
end

module Column
	#name gets 25 cols, arbitrary
	#date created gets 11, hard
	#date due gets 11, hard
	#group gets 20, arbitrary
	#age gets 10, hard, xxDxxMxxY
	COLUMNS = [25, 11, 11, 20, 10]

	def wrap(array, count=1)
		cols = `tput cols`.to_i
		
		#feature: print only name field if
		#cols is less than than COLUMNS
		#	need to break up this method

		string = "| "
		
		while array.join.length > 0
			c = 0

			array.each do |idx|
				#protect against blank user inputs
				idx = "" if idx == nil
				
				#if current array value >= max value, add single space
				#else add blanks to normalize columns 
				if idx.length >= COLUMNS[c]
					string << "#{idx[0...(COLUMNS[c])]} |"
				else
					blanks = (COLUMNS[c] - idx.length)
					string << "#{idx.ljust(COLUMNS[c])} |"
				end
				
				remainder = idx.length - COLUMNS[c]
				if remainder > 0 
					array[c] = idx.split(//).last(remainder).join("")
				else
					array[c] = ""
				end
				c += 1
			end
			
			if string.length > 0
				if count.even?
					puts color(32, 40, "#{string.strip}")
				else
					puts string
				end
			string = "| "
			end
		end
	end
end

class Task
	def initialize
		@datetime = DateTime.now.strftime("%Y-%m-%d")
	end
	
	def collect_task_values
		puts
		"#{prompt_taskname},#{prompt_date},#{@datetime},#{prompt_group}"
	end

	def prompt_taskname
		puts "Enter the new task name:"
		gets.chomp
		#answer = gets.chomp
		#answer == "" ? " " : answer
	end

	def prompt_date
		puts "Due date (can be blank):"
		begin
			due = gets.chomp
			Date.parse(due) unless due == ""
		rescue ArgumentError
			puts "Must be valid date format: yyyy-mm-dd."
			retry
		end
		return due
		#due == "" ? " " : due 
	end
	
	def prompt_group
		puts "Group (can be blank)"
		gets.chomp
		#answer = gets.chomp
		#answer == "" ? " " : answer
	end

end

class User
	include Validation
	include Color
	include Column

	def initialize(user)
		@path = ENV['HOME'] + "/.ruby-taskmanager/"
		@taskfile = @path + user + ".tasklist"
		@user = user
		@actions_allowed = ["add", "remove", "list", "help", "drop", "exit"] 
	end

	def shell
		while true
			print "#{@user}> "
			request = gets.chomp
			self.public_send(request) if @actions_allowed.include?(request)
		end
	end

	def add
		new_task = Task.new
		
		items = []
		CSV.foreach(@taskfile) do |row|
			items << row.join(",")
		end

		items << new_task.collect_task_values
		
		temp_and_replace(@taskfile, items)
	end

	def remove
		self.list

		items = []
		puts "\nNumber of item to remove:"
		remove = gets.chomp

		IO.foreach(@taskfile) do |line|
			items << line
		end
		items.delete_at((remove.to_i) - 1)
		
		temp_and_replace(@taskfile, items)

		list
	end

	def list
		header #print header above user's tasks

		count = 0

		CSV.foreach(@taskfile) do |row|
			wrap(row, count)
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

	private

	def list_user_options
		puts "\nUser options are:",
		"> 'list' your tasks",
		"> 'add' or 'remove' a task",
		"> 'drop' to shell, to change user"
	end
	
	def header
		header = ["Name", "Due", "Created", "Group"]
		wrap(header)
		cols_each = [25, 11, 11, 20, 10]
		puts "-"*(cols_each.reduce {|sum, x| sum + x + 1})
	end

	def calculate_age(past_date)
		#uses Modified Julian Day Number
		#a whole number offset by local time
		Date.parse(@datetime).mjd - Date.parse(past_date).mjd
	end

end

class Shell
	include Validation
	include List

	def initialize
		@path = ENV['HOME'] + "/.ruby-taskmanager/"
		@userlist = @path + "userlist"
		@items = []
		@actions_allowed = ["select", "create", "help", "exit"]
	end

	def start
		introduce
		check_configs
		shell
	end

	def shell
		while true
			print "shell> "
			request = gets.chomp
			self.public_send(request) if @actions_allowed.include?(request)
		end
	end
	
	def create
		puts "Enter your username: "
		user = gets.chomp
		(@items = []) << user

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

	private

	def check_configs
		can_write?(@path, "No permission to write to #{@path}")
		#check config directory
		create_dir_if_missing(@path)
		#check if userlist file missing, create if empty
		create_file_if_missing(@userlist)
		create_user if File.size?(@userlist) == nil
	end

	def introduce
		puts "WELCOME TO TASK MANAGER.",
			"Type 'help' for assistance."
	end

	def list_shell_options
		puts "\nShell options are:",
		"> 'select' user",
		"> 'create' user",
		"> 'help' to show this menu",
		"> 'exit' program"
	end
end

manager = Shell.new.start
