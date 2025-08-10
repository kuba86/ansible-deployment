if status is-interactive
    # Commands to run in interactive sessions can go here
    complete scala-cli -a '(scala-cli complete fish-v1 (math 1 + (count (__fish_print_cmd_args))) (__fish_print_cmd_args))'
end
