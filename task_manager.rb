require "date"
require "csv"
require "yaml"

module Validation
	def temp_and_replace(path, content)
		File.open((path + ".tmp"), "w+") do |file|
			file.puts(content)
		end

		File.rename((path + ".tmp"), path)
	end
	
  def temp_and_replace_yaml(path, content)
		File.open((path + ".tmp"), "w+") do |file|
      file.write(content.to_yaml)
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
	COLUMNS = [25, 11, 11, 20, 10]

  def wrap(file, count=1)
		cols = `tput cols`.to_i
    
    #wrap only first (Name) column if screen too thin for all cols
		if cols < COLUMNS.map().reduce(0, :+)
      wrap_name(file, count)
    else
      wrap_all(file)
    end
  end

  def wrap_name(yaml_file, count)
    array.each do |idx|   #file loaded as array of hashes
      idx.each do |k, v|
        puts color_line(v[:taskname], count)
        count += 1
      end
    end

#    array[0] = "" if array[0] == nil	#protect blank inputs in CSV
 #   color_line(array[0], count)
  end
  
  def wrap_all(array)
    array.each do |idx|
      idx.each do |k, v|
        line = create_task_array(v)
        wrap_and_print(line, k)  #will normalize for printing
      end
    end


    #if line.length > 0
     # return color_line(line, count)
    #end
  end

	def create_task_array(hash)
		c = 0
    
    #create line to normalize and print
		line = []
    hash.each do |k, v|
      line << v
    end

    return line
  end

=begin
    #normalize index to column size, add norm. value to string
    line = normalize(wrapper.to_s, idx, COLUMNS[c])
    
    #any remainder after norm. replaces current index
    array[c] = find_remainder(idx, COLUMNS[c])
    
    c += 1

		line
=end

  def wrap_and_print(array, task_number)
    c = 0
    string = sprintf("%.3d |", task_number)

    while array.join("").length > 0
      while c < COLUMNS.length - 1
        string << normalize(array[c], COLUMNS[c])
        
        array[c] = find_remainder(array[c], COLUMNS[c])
        c += 1
      end
      
      c = 0
      puts color_line(string, task_number)
      string = "    |"
    end
  end

	def normalize(string, indiv_col_width)
		#if current array value >= columns allowed, add single space
		#else add blanks to normalize columns
		if string.length >= indiv_col_width 
			string = "#{string[0...indiv_col_width]} |"
		else
      string = "#{string.ljust(indiv_col_width)} |"
		end
		
		string
	end

	def find_remainder(string, indiv_col_width)
    remainder = string.length - indiv_col_width 
		if remainder > 0 
			new_str = string.split(//).last(remainder).join("")
		else
			new_str = ""
		end
    #puts "New string is: #{new_str}"
    return new_str
	end

	def color_line(line, count)
		if count.even?
			color(32, 40, "#{line.strip}")
		else
			line
		end
	end
end

class Task
	def initialize(taskfile)
		@datetime = DateTime.now.strftime("%Y-%m-%d")
    @taskfile = taskfile
	end

	def collect_task_values
    {find_number => {:taskname => prompt_for_taskname,
     :datedue => prompt_for_date,
     :dateentered => @datetime,
     :group => prompt_for_group
    }
    }
	end

  def find_number
    items = YAML.load(File.open(@taskfile))
    return 1 if items == false  #if file is empty

    nums_seen = []
    items.each do |idx|
      idx.each do |k,v|
        nums_seen << k
      end
    end

    (1..nums_seen.max).each do |x|
      if nums_seen.include?(x) == false
        return x
      end
    end
      
    return (nums_seen.max + 1)
  end

	def prompt_for_taskname
		puts "Enter the new task name:"
		gets.chomp
	end

	def prompt_for_date
		puts "Due date (can be blank):"
		begin
			due = gets.chomp
			Date.parse(due) unless due == ""
		rescue ArgumentError
			puts "Must be valid date format: yyyy-mm-dd."
			retry
		end
		return due
	end
	
	def prompt_for_group
		puts "Group (can be blank)"
		gets.chomp
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
		new_task = Task.new(@taskfile)

    items = []
		
		file = YAML.load(File.open(@taskfile))
    items = file if file != false

    items << new_task.collect_task_values
		
		temp_and_replace_yaml(@taskfile, items)
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

    self.list
	end

	def list
		#header #print header above user's tasks

		count = 0

    wrap(YAML.load(File.open(@taskfile)), count)

=begin
		CSV.foreach(@taskfile) do |row|
			puts(wrap(row, count))
			count += 1
		end
=end
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
		puts(wrap(header))
		cols_each = [25, 11, 11, 20, 10]
		puts "-"*(`tput cols`.to_i)
		#puts "-"*(cols_each.reduce {|sum, x| sum + x + 1})
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
