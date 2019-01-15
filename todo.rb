#!/usr/bin/env ruby

require 'fileutils'

$status_symbol = {false => "[ ]", true => "[x]"}

$output_folder = "/.todo/"
$output_folder_path = ENV['HOME'] + $output_folder
$output_file = "todo.txt"
$output_file_path = $output_folder_path + $output_file

$last_goal_id = 0
$list_modified = false
$goals = []


def check_file()
  unless File.exists?($output_file_path)
    FileUtils.mkdir_p($output_folder_path)
    File.new($output_file_path, 'w')
    puts("An output file does not exist, so it will be created.")
  end
end


# Helper function to determine how many digits are in the passed
# number
# Ex.
# num_of_digits(100)
# returns -> 3
#
def num_of_digits(num)
  digit_counter = 0
  while num > 0
    num = num / 10
    digit_counter += 1
  end
  return digit_counter
end


# Helper function to determine how many spaces to pad after the
# id value so that the formatting stays consist when the id gets
# larger.
# 
def pad_size(id)
  return num_of_digits($last_goal_id + 1) - num_of_digits(id)
end


class Goal
  attr_reader :status, :content
  attr_accessor :id
  def initialize(id, status, content)
    @id = id
    @status = status
    @content = content
  end

  def mark_complete()
    @status = true
  end

  def to_string()
    status = $status_symbol[@status]
    return "#{@id}.#{"".ljust(pad_size(@id))} #{status} #{@content}"
  end
end


# Takes the passed array of goals in string format and parse each
# element. A new goal object is then initialized from the parsed
# information.
#
def convert_to_goals(str_goals)
  id = 1
  for goal in str_goals
    goal_info = []

    # split the information of the received string as
    # [0]<id> [1]<status> [2]<content>
    goal_info = goal.split(/(\[ \])|(\[x\])/)
    status = $status_symbol.key(goal_info.at(1).strip)
    content = goal_info.at(2).strip
    $goals.push(Goal.new(id, status, content))
    id += 1
  end
end


def add_goal(content)
  id = $goals.length + 1
  $goals.push(Goal.new(id, false, content))
end


def finish_goal(id)
  if id > 0
    $goals.at(id-1).mark_complete()
  end
end


def delete_goal(id)
  if id > 0
    $goals.delete_at(id-1)
  end
end


# Read the contents of the output file and store each
# line into an array of string.
# Then call on convert_to_goals(str_goals) to fill
# goal array: $goals with goal objects containing the
# parsed information from the strings in str_goals
#
def load_from_file()
  check_file()
  str_goals = []
  File.open($output_file_path, "r") do |file|
    file.each_line do |line|
      str_goals.push(line)
    end
  end

  $last_goal_id = str_goals.length
  
  convert_to_goals(str_goals)
end


def purge_confirmed()
  puts "Continue with purge? Warning! Once confirmed, it cannot be reversed. [y,N]"
  ans = STDIN.gets.chomp
  case ans
  when 'Y','y'
    return true
  when 'N','n'
    return false
  else
    puts "Purge canceled"
    return false
  end
end


# Checks if there are any arguments passed after the initial options i.e:
# Ex. todo <option> <content> <-- checks if this is missing
# 
def has_valid_args()
  if ARGV[1] == nil
    puts "Missing id or content for the option. Pass -h or --help for what to pass."
    return false
  end
  return true
end


def display_help()
  puts "Todo - a cli todo script written in Ruby"
  puts "Usage:  todo       printout the todo list"
  puts "   or:  todo <argument>"
  puts "   or:  todo <argument> <id/content>"
  puts
  puts "Arguments:"
  puts "  -a,  --add, +        Adds a goal to the list"
  puts '                          Ex. # todo -a "add description of what to do"'
  puts 
  puts "  -x,  --check-off     Check off a goal on the list with the passed id(s)"
  puts "                          Ex. # todo -x 1"
  puts "                          Ex. # todo -x 1 2 3"
  puts
  puts "  -d,  --delete, -     Deletes a goal a on the list with the passed id(s)"
  puts "                          Ex. # todo -d 1"
  puts "                          Ex. # todo -d 4 8 1"
  puts
  puts "  -h,  --help          Displays this help output"
  puts
  puts "  -pg, --purge         Clears the entire list by replacing the goals array with"
  puts "                       an empty list"
end


def process_args()
  # clears the terminal screen to display a clean output
  print "\e[H\e[2J"
 
  case ARGV[0]
  when '-a', '--add', '+'
    if has_valid_args()
      add_goal(ARGV[1])
      $list_modified = true
    end
  when '-x', '--check-off'
    if has_valid_args()
      for id in ARGV[1..-1]
        finish_goal(id.to_i)
      end
      $list_modified = true
    end
  when '-d','--delete', '-'
    if has_valid_args()
      for id in ARGV[1..-1]
        delete_goal(id.to_i)
      end
      $list_modified = true
    end
  when '-h', '--help'
    display_help()
  when '-pg', '--purge'
    if purge_confirmed()
      $goals = []
      puts "Todo list purged"
      $list_modified = true
    end
  else
    display_list()
  end
end

# Reorders the list after editing (adding/removing) current
# list.
#
def update_list() 
  id = 1
  for goal in $goals
    goal.id = id
    id += 1
  end
end


def display_list()
  puts "\tTodo: "
  puts "--------------------------------"
  for goal in $goals
    puts goal.to_string()
  end
end

# Saves the contents of $goals.to_string() to the output
# file.
#
def save_to_file()
  check_file()
  File.open($output_file_path, 'w') do |file|
    for goal in $goals
      file.puts goal.to_string()
    end
  end
  puts "Saved to file"
end

# The "main" function
def run()
  load_from_file()
  process_args()
  update_list()
  if $list_modified
    display_list()
    save_to_file()
  end
end


run()
