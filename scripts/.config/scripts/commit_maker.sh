#!/bin/bash

# COLORS ==============================================================
reset="\e[0m"
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
white="\e[39m"
cyan="\e[96m"
bold="\e[1m"
dim="\e[2m"

# VAR =================================================================
welcome="⚡️ ${bold}${cyan}Weclome to ${white}commit_maker${reset} ⚡️\n"
header="⚡️ ${bold}${white}commit_maker${reset} ⚡️\n"
types=("add" "feat" "fix" "test" "refactor" "structure" "style" "merge" "doc" "finish")
emojis=("➕" "✨" "🔧" "🧪" "♻️ " "🏗️ " "🎨" "🔀" "📝" "🚀")
selected=0

# FUNC ================================================================
clear_and_print() {
  clear
  echo -e $1
}

commit_preview() {
  clear_and_print "$header"
  echo -e "${dim}Preview →${reset} \" $1$2${reset} \"\n"
}

print_menu() {
  clear_and_print "$welcome"
  echo -e "${bold}Choose a type of modification${reset}"
  echo -e "${dim}Use ↑/↓ to choose, Enter to select:${reset}"
  echo
  for i in "${!types[@]}"; do
    if [[ $i -eq $selected ]]; then
      echo -e "${bold}${cyan}► ${types[$i]}${reset}"
    else
      echo "  ${types[$i]}"
    fi
  done
}

reset_tput() {
  clear_and_print "$header"
  echo -e "❌ ${red}Commit aborted${reset} ❌\n"
  tput cnorm
  exit 1
}

# =====================================================================
# START ---------------------------------------------------------------
# =====================================================================

# DEFINE TYPE =========================================================
trap reset_tput SIGINT
tput civis
while true; do
  print_menu
  read -rsn1 key
  if [[ $key == $'\x1b' ]]; then
    read -rsn2 key
    case "$key" in
    '[A') ((selected--)) ;;
    '[B') ((selected++)) ;;
    esac
  elif [[ $key == "" ]]; then
    break
  fi
  # first + upArrow = last & last + downArrow = first
  ((selected < 0)) && selected=$((${#types[@]} - 1))
  ((selected >= ${#types[@]})) && selected=0
done
tput cnorm

type=${types[$selected]}
emoji=${emojis[$selected]}
message="$emoji $type"

commit_preview "${yellow}" "$message ${reset}${dim}..."
echo -e "${green}✓${reset} Type : ${green}$type${reset}"
echo -ne "$cyan►${reset} Scope : $cyan"

# DEFINE SCOPE ========================================================
read scope
echo -e ${reset}
if [[ -z $scope ]]; then
  message+=": "
else
  message+="($scope): "
fi

commit_preview "${yellow}" "$message ${reset}${dim}..."
echo -e "${green}✓${reset} Type : ${green}$type${reset}"
if [[ -z $scope ]]; then
  echo -e "$red✓${reset} Scope : ${dim}no scope${reset}"
else
  echo -e "${green}✓${reset} Scope : ${green}$scope${reset}"
fi

# DEFINE DESC =========================================================
while [[ -z $desc ]]; do
  echo -ne "$cyan►${reset} Description : $cyan"
  read desc
done
echo -e "${reset}\n"
message+="$desc"
commit_preview "${yellow}" "$message"
echo -e "${green}✓${reset} Type : ${green}$type${reset}"
if [[ -z $scope ]]; then
  echo -e "$red✓${reset} Scope : ${dim}no scope${reset}"
else
  echo -e "${green}✓${reset} Scope : ${green}$scope${reset}"
fi
echo -e "${green}✓${reset} Description : ${green}$desc${reset}\n$dim"

echo -e "Press Enter to contiue ...${reset}"
tput civis
read -rsn1 key
while [[ $key != "" ]]; do
  read -rsn1 key
done
tput cnorm

#CONFIRM ==============================================================
commit_preview "${green}" "$message"
while [[ $conf != "y" && $conf != "n" ]]; do
  echo -ne "⚠️  Confirm commit message [${green}y${reset}/${red}n${reset}] : "
  read -n1 conf
  echo -e "${reset}\n"
done
if [[ $conf == 'n' ]]; then
  echo -e "❌ ${red}Commit aborted${reset} ❌\n"
else
  clear_and_print "$header"
  echo -e "✅ ${green}Confirmed commit message${reset} ✅\n"
  echo -e "${dim}Press Enter to contiue ...${reset}"
  tput civis
  read -rsn1 key
  while [[ $key != "" ]]; do
    read -rsn1 key
  done
  tput cnorm
  clear_and_print "$header"
  echo -ne "🛤️  Path to the .git ? ${dim}[default = ./]${reset} : "
  read path
  if [[ -z $path ]]; then
    path="$PWD/"
  fi
  cd $path
  git commit -m "$message" --quiet
fi
