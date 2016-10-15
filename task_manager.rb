require "date"

module DirectoryChanging
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
		if File.exist?(path) == false
			File.new(path, "w+") 
			puts ("Created file: #{path}")
		end
	end

	def can_write?(path)
		raise ArgumentError.new("No permission to write to #{path}.") unless File.stat(path).writable?
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

##FIND SOMEWHERE FOR THIS
	def grab_username
		puts("\nWhat is your username?")
		@username = gets.chomp
	end
##

class User
	include DirectoryChanging 

	def initialize(user)
		@@path = ENV['HOME'] + "/.ruby-taskmanager/"
		@taskfile = @@path + user + ".tasklist"
		@items = []
		@user = user
	end

	def add
		can_write?(@@path)

		new_task = Task.new
		
		create_file_if_missing(@taskfile)

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
		if File.exist?(@taskfile)
			print "\nUser: #{@user}"
			#foreach better for larger files
			#wont load whole file into memory at once
			#overkill here, but good to learn
			count = 1
			puts "\nYour tasks are:"
			IO.foreach(@taskfile) do |line|
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

		temp_and_replace(@userconfig, new_user.username)
		
		puts "Added '#{new_user.username}' to user config in: #{@userconfig}."
	end
end

class UserInterface
	include DirectoryChanging 

	def initialize
		@path = ENV['HOME'] + "/.ruby-taskmanager/"
		@userlist = @path + "userlist"
	end

	def check_configs
		#check config directory
		create_dir_if_missing(@path)
		#check if users
		create_user if File.size?(@userlist) == nil
	end

	def create_user
		puts "Enter your username: "
		temp_and_replace(@userlist, gets.chomp)
	end
	
	def introduce
		puts "WELCOME TO TASK MANAGER."
	end

	def list_options
		puts "\nOptions are:",
		"> 'list' your tasks",
		"> 'add' a task",
		"> 'remove' the last entered task",
		"> 'update' user info",
		"> 'exit' program."
		puts  "-------------- "
		print "Choose a task: "
	end

	def command
		puts  "-------------- "
		print "Choose a task: "
	end
	
	def list_users
		create_file_if_missing(@userlist)

		c = 1

		IO.foreach(@userlist) do |line|
			puts c.to_s + ". " + line
			c += 1
		end
	end

	def start_user_session 
		puts "\nSelect user (type name): "
		list_users
		@session = User.new(gets.chomp)
	end
	
	def process_option 
		while true
			request = gets.downcase.chomp
			#new_action = User.new(choose_user)

			if request == "switch"
				start_user_session
			elsif @session.respond_to?(request)
				@session.send(request)
			else
				puts "\nERROR: That action is not available."
			end

			command
		end
	end
end

start = UserInterface.new
start.introduce
start.check_configs
start.start_user_session
start.list_options
start.process_option
