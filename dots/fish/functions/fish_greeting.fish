function fish_greeting
    echo -ne '\x1b[38;5;16m'  # Set colour to primary
    echo '     ______         ____  _____ '
    echo '    / ____/  __    / __ \/ ___/ '
    echo '   / /   | |/_/   / / / /\__ \  '
    echo '  / /___ _>  <   / /_/ /___/ /  '
    echo '  \____//_/|_|   \____//____/   '
    set_color normal
    command -v fastfetch &> /dev/null && fastfetch --key-padding-left 5
end
