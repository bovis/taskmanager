#file should first seek input from user to create a task
#I'm not sure I know how to delete line items yet
#
#for ch2, include:
# ** use load to list file contents
# ** local variables
# ** create a new object
# ** send information to a method
# - use object_id, respond_to?, and send() built-in methods
# - use required, optional, and default-valued arguments
# - include references from one variable to another, alter them sufficiently

operation = Object.new

def operation.add
	filename = "tasklist"
	if File.stat(filename).writable? != true
		puts "Permission denied."
		return
	end

	if File.file?(filename) != true
		puts "File not found. Creating new."
		File.new(filename, "w")
	else
		puts "File found."
		puts()
	end
	
	print "What is the name and date of the ",
	"task you want to record?"
	puts()
	new_task = gets.chomp

	open(filename, "a") do |file|
		file.puts(new_task)
	end

	puts "Added '#{new_task}' to file name: #{filename}."
end

def operation.remove
	puts "Future consideration."
end

def operation.list
	filename = "tasklist"
	puts()
	puts "Your tasks are:"
	puts File.read(filename)
end

puts "What would you like to do?"
puts "Options are 'list, 'add', and 'remove'."
action = gets.downcase.chomp

if operation.respond_to?(action)
        operation.send(action)
else
        puts "That action is not available."
end

