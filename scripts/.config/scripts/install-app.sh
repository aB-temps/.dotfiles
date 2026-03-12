#! /bin/bash

check_args()
{
	local argc=$1

	if [ "$argc" -lt 1 ]; then
		echo -e "usage:\ninstall-app <app1.AppImage> <...> <appN.AppImage>\n"
		return 1
	else
		return 0
	fi
}


main()
{
	local argc=$#
	check_args "$argc"

	if [ $? -eq 1 ]; then 
		return 1
	fi

	chmod +x "$*"

	for var in $@; do
		./$var --appimage-extract
		mv "squashfs-root" "$(echo $var | sed 's/\.AppImage$//')"
	done

}

main $@
