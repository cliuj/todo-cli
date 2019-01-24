#!/usr/bin/env ruby

require 'fileutils'

$status_symbol = {false => "[ ]", true => "[x]"}

$outputs_folder = "/.todo/"
$outputs_folder_path = ENV['HOME'] + $outputs_folder

$list_file = "todo.txt"
$list_file_path = $outputs_folder_path + $list_file

$log_file = "todo_log_#{Time.now.strftime("%y-%m-%d")}.txt"
$log_file_path = $outputs_folder_path + $log_file

$last_goal_id = 0
$list_modified = false
$goals = []
$completed = []
$not_completed = []


def check_file(file)
  unless File.exists?(file)
    FileUtils.mkdir_p($outputs_folder_path)
    File.new(file, 'w')
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

  def mark_uncomplete()
    @status = false
  end

  def edit_content(new_content)
    @content = new_content
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

    if status == true
      $completed.push(id - 1)
    else
      $not_completed.push(id - 1)
    end
    id += 1
  end
end


def add_goal(content)
  id = $goals.length + 1
  $goals.push(Goal.new(id, false, content))
end


def finish_goal(id)
  puts id
  if id > 0 && id < $goals.length + 1
    $goals.at(id - 1).mark_complete()
  end
end

def unfinish_goal(id)
  puts id
  if id > 0 && id < $goals.length + 1
    $goals.at(id - 1).mark_uncomplete()
  end
end


def swap_goals(id1, id2)
  if id1.between?(0, $goals.length - 1) && id2.between?(0, $goals.length - 1)
    $goals[id1], $goals[id2] = $goals[id2], $goals[id1]
    $goals
  end
end


def sort_list()
  sorted_goals = []
  for id in $not_completed
    sorted_goals.push($goals[id])
  end

  for id in $completed
    sorted_goals.push($goals[id])
  end

  $goals = sorted_goals
end


def delete_goal(id)
  if id > 0
    $goals.delete_at(id-1)
  end
end

def edit_goal(id, new_content)
  if id > 0 && id < $goals.length + 1
    $goals.at(id - 1).edit_content(new_content)
  end
end


# Read the contents of the output file and store each
# line into an array of string.
# Then call on convert_to_goals(str_goals) to fill
# goal array: $goals with goal objects containing the
# parsed information from the strings in str_goals
#
def load_from_file(input_file)
  check_file(input_file)
  str_goals = []
  File.open(input_file, "r") do |file|
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
  puts "  +,  -a,   --add,          Adds a goal to the list"
  puts '                              Ex. # todo -a "add a todo"'
  puts 
  puts "      -x,   --check-off     Check off a goal on the list with the passed id(s)"
  puts "                              Ex. # todo -x 1"
  puts "                              Ex. # todo -x 1 2 3"
  puts 
  puts "      -ux,  --uncheck      Unchecks goal(s) on the list with the passed id(s)"
  puts
  puts "  -,  -d,   --delete        Deletes a goal a on the list with the passed id(s)"
  puts "                              Ex. # todo -d 1"
  puts "                              Ex. # todo -d 4 8 1"
  puts
  puts "      -swp, --swap          Swaps the ids(places) of the passed 2 ids"
  puts
  puts "      -h,   --help          Displays this help output"
  puts
  puts "      -pg,  --purge         Clears the entire list by replacing the goals array with"
  puts "                            an empty list"
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
  puts "Todo:                           "
  puts "--------------------------------"
  for goal in $goals
    puts goal.to_string()
  end
end


def log_to_file()
  save_to_file($log_file_path)
end

# Saves the contents of $goals.to_string() to the output
# file.
#
def save_to_file(file)
  check_file(file)
  File.open(file, 'w') do |file|
    for goal in $goals
      file.puts goal.to_string()
    end
  end
  puts "Saved to #{file}"
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

  when '-ux', '--uncheck'
    if has_valid_args()
      for id in ARGV[1..-1]
        unfinish_goal(id.to_i)
      end
      $list_modified = true
    end

  when '-e', '--edit'
    id = ARGV[1].to_i
    new_content = ARGV[2]
    edit_goal(id, new_content)
    $list_modified = true

  when '-d','--delete', '-'
    if has_valid_args()
      for id in ARGV[1..-1]
        delete_goal(id.to_i)
      end
      $list_modified = true
    end

  when '-swp', '--swap'
    id1 = ARGV[1].to_i
    id2 = ARGV[2].to_i
    swap_goals(id1 - 1, id2 - 1)
    $list_modified = true
  
  when '-s', '--sort'
    sort_list()
    $list_modified = true

  when '-h', '--help'
    display_help()

  when '-lg', '--log'
    log_to_file()

  when '-pg', '--purge'
    if purge_confirmed()
      $goals = []
      puts "Todo list purged"
      $list_modified = true
    end

  else
    if $goals.empty?
      puts "Your todo list is currently empty, here's a list of options you can do:"
      puts
      display_help()
    else
      display_list()
    end
  end
end


# The "main" function
def run()
  load_from_file($list_file_path)
  process_args()
  update_list()
  if $list_modified
    display_list()
    save_to_file($list_file_path)
  end
end

run()
