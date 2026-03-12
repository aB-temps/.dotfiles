function fish_alias
	if  [ (count $argv) -ne 2 ];
		echo "wrong number of argument."
		return 1
	end
	echo "alias $argv[1]=\"$argv[2]\"" >> "$HOME/.dotfiles/fish/.config/fish/conf.d/alias.fish"
	echo "alias $argv[1]=$argv[2] has been created!"
end
