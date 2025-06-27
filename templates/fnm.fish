if status is-interactive
    /home/{{ main_user }}/.local/share/fnm/fnm env --use-on-cd --shell fish | source
end
