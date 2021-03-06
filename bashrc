#
# ~/.bashrc
#

## .bashrc vs .bash_profile: nothing but annoying
# if non-interactive shell:
#   echo $- = hB (e.g.); "i" is not included
# if interactive shell:
#   echo $- = himBHs (e.g.); "i" is included 
#   run 1) /etc/bash.bashrc, 2) ~/.bashrc
#   if login shell:
#       echo $0 = "-bash" or `shopt login_shell` = on
#       on login:  run 1) /etc/profile, 2) ~/.bash_profile, 3) ~/.bash_login, 4) ~/.profile
#       on logout: run 1) ~/.bash_logout, 2) /etc/bash.bash_logout
#   if non-login shell:
#       echo $0 = "bash" or `shopt login_shell` = off
#       on login: run ~/.bashrc
# a) start a new shell with `bash`           -->     interactive & non-login shell --> bashrc
# b) connect via ssh                         -->     interactive &     login shell --> bash_profile 
# c) submit a command via ssh or scp a file  --> non-interactive & non-login shell --> bashrc
# d) from within a bash script (#!/bin/bash) --> non-interactive & non-login shell --> none
# --> conclusion: you always need both: .bashrc and .bash_profile, i.e. the most complicated way was chosen -_-
# https://wiki.archlinux.org/index.php/bash#Invocation
# https://linux.die.net/man/1/bash (incovation chapter)
# https://www.gnu.org/software/bash/manual/bash.html#Bash-Startup-Files

# If not running interactively, don't do anything
[[ $- != *i* ]] && return
#if [[ $- != *i* ]]; then
    #echo "*** .bashrc non-interactive session ***" 
    #echo "\$- = $-"
    #if shopt -q login_shell; then
    #    echo "\$0 = -$(basename $SHELL) or \`shopt login_shell\` = on -> login shell"
    #else
    #    echo "\$0 = $(basename $SHELL) or \`shopt login_shell\` = off -> not login shell"
    #    fi
    #echo "***************************************" 
    
## From here, everyhing happens only if running interactively
#else

    nch=30 # columns to print
    ncol=$(($(tput cols)/2))
    ncol=$(($ncol<$nch?$ncol:$nch)) # = min(ncol,nch)
    printf '%*s' "$ncol" | tr ' ' "*"
    printf " ~/.bashrc start "
    printf '%*s' "$ncol" | tr ' ' "*"
    echo ""

    # Source global definitions
    if [ -f /etc/bashrc ]; then
        source /etc/bashrc
    fi

    # use bash completion, if installed
    if [ -f /etc/bash_completion ]; then
        source /etc/bash_completion
    fi

    # git automplete
    # from https://apple.stackexchange.com/questions/55875/git-auto-complete-for-branches-at-the-command-line
    # does not work
    #if [ -f ~/.git-completion.bash ]; then
    #    source ~/.git-completion.bash
    #fi
    
    # enable git colors
    #git config --global color.ui auto
    
    # my bins (doing this recursively is not recommended; security)
    if [ -d ~/bin ]; then
        export PATH=~/bin:$PATH
    fi
    if [ -d ~/.local/bin ]; then
        export PATH=~/.local/bin:$PATH
    fi

    # default prompt
    PS1='[\u@\h \W]\$ '

    # my prompt
    PS1='\[\033[0;34m\]\h:$(pwd)/>\[\033[0m\] '

    # attach cpu temp to prompt if available
    if [ -x "$(command -v sensors)" ]; then
        show_temp(){
            sensors | grep -oP 'Package id 0.*?\+\K[0-9.]+'
        }
        PS1='\[\033[0;34m\]\h:$(show_temp)°C:$(pwd)/>\[\033[0m\] '
    fi

    # use liquidprompt if available https://github.com/nojhan/liquidprompt
    if [ -x "$(command -v liquidprompt)" ]; then
        # add cpu temp to liquidprompt
        # this is not perfect way yet
        # check ~/.liquidpromptrc
        #PROMPT_COMMAND=show_temp
        if [ -n "$(LC_ALL=C type -t show_temp)" ] && [ "$(LC_ALL=C type -t show_temp)" = function ]; then
               LP_PS1_PREFIX="$(show_temp)°C "
        fi
        source liquidprompt # need to source here because its not bash?!

    else 
        echo could not load liquidprompt
    fi

    # enable make autocomplete:
    # https://stackoverflow.com/questions/4188324/bash-completion-of-makefile-target
    complete -W "\`grep -oE '^[a-zA-Z0-9_.-]+:([^=]|$)' Makefile | sed 's/[^a-zA-Z0-9_.-]*$//'\`" make

    # helper functions
    # check if program exists also if its masked by alias
    # if [ -x "$(command -v vi)" ]; then will not work if vi is aliased
    # https://unix.stackexchange.com/questions/85249/why-not-use-which-what-to-use-then/85250#85250
    getmod () {
        stat --format '%a' $1
    }
    check_existance(){
        if command -v $1 > /dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    }
    tl(){
        file=$(ls -t *.log | head -n1)
        echo `ls --color=auto -lFh $(pwd)/$file`
        tail -f $file
    }
    ml(){
        file=$(ls -t *.log | head -n1)
        echo `ls --color=auto -lFh $(pwd)/$file`
        less -i $file
    }
    pwd2(){
        printf "\$(readlink -f .) = "
        readlink -f . # or pwd -P
    }
    pwd3(){
        printf "lfs getstripe --mdt-index $(readlink -f .): "
        lfs getstripe --mdt-index .
    }
    ddiff(){
        diff $1 $2 | vim -R -
    } # or `diff old new | colordiff`
    myfind(){
        if [ $# -eq 0 ]; then
            echo "Usage: myfind search_pattern"
            return 1
        else
            find -print 2>/dev/null | grep -i $1 
        fi
    }
    when(){ 
        # info: /usr/share/zoneinfo and timedatectl list-timezones
        remote_date_user="$@"
        if [ "z$remote_date_user" != "z" ] && date -d "$remote_date_user" > /dev/null; then
            #echo "date \"$remote_date_user\" valid"
            echo "run tzselect ..."
            tz=$(tzselect)
            #echo "tz: \"$tz\""
            # get correct remote date
            remote_date=$(TZ="$tz" date -d "$remote_date_user")
            local_date=$(date -d "TZ=\"$tz\" $remote_date_user")
            remote_dh_to_utc_char=$(TZ="$tz" date -d "$remote_date_user" +%z)
            local_dh_to_utc_char=$(date -d "TZ=\"$tz\" $remote_date_user" +%z)
            remote_dh_to_utc_num=$(TZ="$tz" date -d "$remote_date_user" +%z | sed -E 's/^([+-])(..)(..)/scale=2;0\1(\2 + \3\/60)/' | bc)
            local_dh_to_utc_num=$(date -d "TZ=\"$tz\" $remote_date_user" +%z | sed -E 's/^([+-])(..)(..)/scale=2;0\1(\2 + \3\/60)/' | bc)
            # calc diff
            dt_hour=$( bc <<<"$local_dh_to_utc_num - $remote_dh_to_utc_num" )
            #echo "dt_hour = $dt_hour"
            echo "" 
            echo "Provided $tz time $remote_date_user is"
            echo "$remote_date (UTC $remote_dh_to_utc_char = $remote_dh_to_utc_num), i.e. my corresponding local time"
            printf "$local_date (UTC $local_dh_to_utc_char = $local_dh_to_utc_num) is "
            if (( $(echo "$dt_hour == 0" |bc -l) )); then
                echo "at the same time)"
            else
                printf "%s" "abs($local_dh_to_utc_num - $remote_dh_to_utc_num) = ${dt_hour#-} hour"
                (( $(echo "${dt_hour#-} > 1" |bc -l) )) && printf "s"
                (( $(echo "$dt_hour >= 0" |bc -l) )) && echo " later"
                (( $(echo "$dt_hour < 0" |bc -l) )) && echo " earlier"
            fi
        else
            return 1
        fi
    }
    archhelp(){
        echo "journalctl --follow # or -f"
        echo "journalctl --since=today"
        echo "journalctl -b -1 # since last boot"
        echo "journalctl --since=today | grep -B 15 '(EE) Backtrace:'"
        echo "loginctl session-status # get session details"
        echo "dmesg -T"
        echo "tail -f /var/log/Xorg.0.log"
        echo "mate-session-properties # get mate session details"
        echo "lspci -k | grep -iEA5 'vga|3d|display # get hardware info"
        echo "xrandr; hwinfo --monitor; glxinfo"
        echo "grep '/usr/s\?bin' /etc/systemd/system/display-manager.service # which login manager"
        echo "ntpq -p # update wrong time after reboot"
        echo "ip addr / ip link / ip r / ip tuntap show / ifconfig -a"
        echo "yarn cache clean"
        echo "sudo paccache -r"
        echo "yay -Yc # clean unneeded dependencies"
        echo "yay -Scc # clean cache"
        echo "pacman -U /var/cache/pacman/pkg/fname.pkg.tar.xz # downgrade"
    }
    bashhelp(){
        echo "./script > script.log 2>&1 &"
        echo "ln -sfn path/to/file-name link-name"
        echo "find /usr/local/bin -lname '/usr/local/texlive/*'" -delete # delete links
        echo "find / -iname openssl.pc 2>/dev/null \# locate alternative"
        echo "for f in *1954*; do echo \$f; ln -s \$(pwd)/\$f /aim/\$f; done"
        echo "rename 's/\.DAT/\.dat/' * \# -n for dry"
        echo "wget -r -no-parent -e robots=off url"
        echo "while read -r f; do mv "$f" "${f//:/_}"; done <files.txt"
    }
    vimhelp(){
        echo "find missing bracket: 1) cursor on open or close bracket 2) %"
    }
    tarhelp(){
        echo "https://www.gnu.org/software/tar/manual/html_section/"
        echo "tar -cvf archive.tar f1 f2 # [c]reate archive named <[f]ile>"
        echo "tar -xvf archive.tar # e[x]tract archive named <[f]ile>"
        echo "tar -xvf archive.tar --wildcards \"*.nc\""
        echo "tar -xvf archive.tar --wildcards *{pat1,pat2}*nc"
    }
    markdownhelp(){
        echo "<details>"
        echo "<summary>Click to expand</summary>"
        echo "# blank line"
        echo "..."
        echo "</details>"
    }
    githelp(){
        echo "git lol = git log --graph --decorate --pretty=oneline --abbrev-commit"
        echo "git lola = git log --graph --decorate --pretty=oneline --abbrev-commit --all"
        echo diff
        echo "git diff [from] to"
        echo "git diff --name-only"
        echo "git diff 6843db8 -- '*.functions'"
        echo "git -c core.fileMode=false diff # temporarily exclude file mode changes"
        echo stash
        echo "git stash list; stash show -p [stash@{1}]; stash apply stash@{n}; stash drop stash@{2}"
        echo cherry-pick
        echo "git checkout commitx"
        echo "git cherry-pick commity [commitz1 commitz2]"
        echo "git cherry-pick --strategy=recursive -X theirs 7501f4d"
        echo squash
        echo "git checkout branchname"
        echo "git rebase -i HEAD~n # combine latest n commits"
        echo "@editor: first line let \"pick\"; all other lines from \"pick\" --> \"squash\""
        echo "git push -u origin +branchname # \"+\" similar as --force but different"
        echo "@other pc: git reset --hard origin/branchname # caution: overwrites potential local changes irreversible"
        echo "rebase branch"
        echo "git checkout commit_from_where_my_branch_should_start"
        echo "git branch new_branch # create"
        echo "git cherry-pick commit_i_want_to_include"
        echo "git branch -d old_branch # delete old branch locally"
        echo "git push origin --delete old_branch # delete old branch remote"
        echo "@other pc: git remote prune origin # to delete the old branch in the 'git branch -av' list"
    }
    llg(){
        repofiles=$(git ls-tree --full-tree --name-only -r HEAD) # string l=1
        if [ $? -ne 0 ]; then
            return 1
        fi
        declare -a repofiles_vec=($repofiles) # array l=n
        #printf ' %s' "${repofiles_vec[@]}"
        nrepofiles=${#repofiles_vec[@]} # n
        rootpath=$(git rev-parse --show-toplevel) # may include unneeded prefixes
        declare -a vec=()
        for i in $(seq 0 $(( $nrepofiles - 1))); do # concatenate path and files
            #echo "$i: ${repofiles_vec[$i]}"
            vec[$i]="$rootpath/${repofiles_vec[$i]}"
        done # todo: without loop
        #printf ' %s' "${vec[@]}"
        printf -v repofiles ' %s' "${vec[@]}" # convert array back to string
        dus=$(du -hc $(echo $repofiles)) # for `du`, /home/user` cannot be abbreviated with `~/`
        homeprefix=$(readlink -f ~/)
        patt='~' # need this extra variable for line below
        dus="${dus//$homeprefix/$patt}" # replace "[/optional/prefix]/home/user" with pattern $patt
        printf '%s\n' "${dus[@]}"
        echo "--> $nrepofiles tracked files in repo ${rootpath//$HOME/$patt}"
    }
    cdohelp(){
        echo "man cdo does not exist: cdo manual -> Intro -> Usage -> Options"
        echo "cdo --operators"
        echo "cdo -h [operator] # e.g. cdo -h after"
        echo "cdo -b f32 copy  infile ofile \# convert short to float with add_offset and scale_factor" 
        echo "cdo [-t echam6] -f nc copy file.grb file.nc"
        echo "cdo -f nc -t ecmwf -setgridtype,regular"
        echo "for f in *01.grb; do echo \$f; cdo -t echam6 -f nc copy \$f \$f.nc; done"
        echo "cdo -select,name=temp2 *echam6_echam_* tmp1 && cdo fldmean tmp1 tmp2 && ncview tmp2" 
        echo "cdo -select,name=var167 *echam6_echam_* tmp1 && cdo fldmean tmp1 tmp2 && ncview tmp2" 
        echo "cdo chname,var1,var2 in.nc out.nc"
        echo "for f in *.nc; do echo \$f; ncrename -v XXX,YYY \$f; done"
        echo "for f in *.nc; do echo \$f; ncdump -h \$f | grep var167; done"
        echo "cdo -r copy in out"
        echo "cdo -seltimestep,$(cat steps | tr ' ' ',') in out"
        echo "cdo trend in intercepts slopes"
        echo "export CDO_WEIGHT_MODE=off; export MAX_JACOBI_ITER=100"
        echo "cdo sub fin -timmean fin anom_fin"
        echo "cdo eof,40 anom_fin eigen_val eigen_vec" 
        echo "cdo eofcoeff eigen_vec anom_fin obase"
    }
    ncohelp(){
        echo "ncap2 -O -s 'TEMP=double(TEMP)' in.nc out.nc"
    }
    condahelp(){
        echo "conda create -y -p /path <env>"
        echo "source activate <env>"
        echo "source deactivate"
        echo "conda env list"
        echo "conda list"
        echo "conda install -c <chan> <pkg>"
        echo "conda clean --all"
        echo "conda env remove -n <env> \# this removes all packages installed in <env>"
    }
    texhelp(){
        echo "latexdiff -t CFONT old.tex new.tex > changes.tex \# for error"
    }
    inkscapehelp(){
        echo "clip/mask: draw rectangle over area you want to clip. select both. objects -> clip -> set"
        echo "crop white space: select -> edit -> resize page to selection"
    }
    
    # argument list too long
    #/bin/echo "$(printf "%*s" 131071 ".")" > /dev/null
    #/bin/echo "$(printf "%*s" 131072 ".")" > /dev/null --> too long
    # --> $(getconf PAGE_SIZE)*32 = 4096*32 = 131072
    # --> this is hardcoded in binfmts.h
    # getconf ARG_MAX = 2097152
    # too long: 2612711 characters wout multiple spaces
    # ok:       2612710 characters wout multiple spaces
    # start counting from: `cdo a b`
    #                          1234 -> nchar = 4 in this example
    # --> it seems multiple spaces count as single spaces
    # --> it seems to be independet of the number of input files provided (29355 in this example)

    # aliase
    # check aliase with 'type alias'
    alias ll='ls --color=auto -lFh'
    alias la='ls --color=auto -alFh'
    alias ls='ls --color=auto -F' # default: ls='ls --color=auto'
    # ls only files excluding .dotfiles
    alias lsf='find . -maxdepth 1 -type f -a ! -iname '\''.*'\'' -print0 | xargs -0r ls'
    # ls only files including .dotfiles
    alias lsf2='find . -maxdepth 1 -type f -print0 | xargs -0r ls'
    alias grep="grep --color=auto"
    alias R='R --quiet'
    alias R0='unalias R 2>/dev/null; R --no-init-file'
    alias vi='vim'
    if check_existance vimx; then
        alias vi='vimx' # for +clipboard
        alias vim='vimx'
    fi
    alias less="less -i"
    alias more="less"

    # own variables
    export VISUAL=vim
    export EDITOR="$VISUAL" # also applies to git
    # todo: need to convert these to functions:
    export compress='gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/default -dNOPAUSE -dQUIET -dBATCH -dDetectDuplicateImages -dCompressFonts=true -r150 -sOutputFile=output.pdf input.pdf'
    export cut='gs -dBATCH -sOutputFile= -dFirstPage= -dLastPage= -sDEVICE=pdfwrite infile'
    export cat1='gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile=out.pdf in1.pdf in2.pdf'
    export cat2='pdftk in.pdf cat 1-12 14-end output out.pdf'
    export cat3='pdftk in1.pdf in2.pdf output out.pdf'
    export crop='pdfcrop --xetex --resolution 72 diffusion_vs_res.pdf diffusion_vs_res.pdf'
    # watch -n 0.1 ls

    # hostname
    printf "\$(hostname)@\$(hostname -d): "
    echo "$(hostname)@$(hostname -d)"
  
    # check cpus
    if check_existance lscpu; then
        printf "/proc/cpuinfo: "
        cat /proc/cpuinfo | grep --color=never "model name" | head -1
        #printf "lscpu | grep Model name::"
        #lscpu | grep --color=never "Model name:"
        printf "\$(nproc): "; nproc
        #lscpu | grep --color=never "^CPU(s):"
    fi

    # uptime
    printf "\$(uptime): "
    uptime | awk -F'( |,|:)+' '{print $6,$7",",$8,"hours,",$9,"minutes"}'

    # which OS/distro
    if [ -f /proc/version ]; then
        echo "cat /proc/version:"
        cat /proc/version # gives distro name; `uname` does not; `lsb_release -a` not always available
    else
        echo "/proc/version does not exist. what crazy OS/distro is this!?"
    fi
    
    # which desktop environment (de) is used
    echo "pgrep -l \"gnome|kde|mate|cinnamon|lxde|xfce|jwm\":"
    pgrep -l "gnome|kde|mate|cinnamon|lxde|xfce|jwm" | cut -d " " -f 2 | tr '\n' ';'; echo
    if [ ! $DESKTOP_SESSION == "" ]; then
        echo "\$DESKTOP_SESSION = $DESKTOP_SESSION"
    fi
    if [ ! $XDG_CURRENT_DESKTOP == "" ]; then
        echo "\$XDG_CURRENT_DESKTOP = $XDG_CURRENT_DESKTOP"
    fi
    if [ ! $GDMSESSION == "" ]; then
        echo "\$GDMSESSION = $GDMSESSION"
    fi
    # which display manager (dm) is used
    tmp=$(ps auxf | awk '{print $11}' | \grep -e "^/.*dm$" -e "/.*slim$") # dm for display manager
    if [ ! $tmp == "" ]; then
        printf "ps auxf | awk '{print \$11}' | \\grep -e dm\$ -e slim\$ = "
        printf "%s" $tmp; echo
        unset tmp
    fi
    # which window manager (wm) is used
    #id=$(xprop -root -notype | awk '$1=="_NET_SUPPORTING_WM_CHECK:"{print $5}') # too slow on hpc
    #xprop -id "${id}" -notype -f _NET_WM_NAME 8t | grep "_NET_WM_NAME = " | cut --delimiter=' ' --fields=3 | cut --delimiter='"' --fields=2

    # which package manager 
    declare -A osInfo;
    osInfo[/etc/redhat-release]=yum
    osInfo[/etc/arch-release]=pacman
    osInfo[/etc/gentoo-release]=emerge
    osInfo[/etc/SuSE-release]=zypp
    osInfo[/etc/debian_version]=apt-get
    for f in ${!osInfo[@]}; do
        if [[ -f $f ]]; then
            echo "\"$f\" exists -> package manager is ${osInfo[$f]}"
        fi
    done

    # print free disk space on ~/ 
    if check_existance tr; then
        if check_existance cut; then
            printf "~/ "
            df -h ~/
        fi
    fi

    # which tty
    printf "\$(tty): "; tty
    #set -o vi # unfortunatley this breaks ctrl+a/+e
    # kill open remote sessions:
    #ssh cdanek@stan1.awi.de w
    #ssh cdanek@stan1.awi.de pkill -9 -t pts/3
    #ssh cdanek@stan1.awi.de pkill -u cdanek

    # which shell
    printf "\$SHELL: "; echo $SHELL

    # show what kind of shell (at this point it must be an interactive shell since)
    # h: Remember the location of commands as they are looked up for execution.  This is enabled by default.
    # i: interactive
    # m: Monitor mode.  Job control is enabled
    # B: The shell performs brace expansion (see Brace Expansion above).  This is on by default
    # H: Enable !  style history substitution.  This option is on by default when the shell is interactive.
    printf "\$- = \"$-\""
    if [[ $- == *i* ]]; then
        printf " --> \"i\" for interactive shell"
    fi
    echo

    # check if login shell (cannot check $0 from within this script)
    if check_existance shopt; then
        if shopt -q login_shell; then
            echo "\$0 = \"-$(basename $SHELL)\" or \`shopt login_shell\` = on -> login shell"
        else
            echo "\$0 = \"$(basename $SHELL)\" or \`shopt login_shell\` = off -> not login shell"
        fi
    else
        echo "cannot check if this is a login or non-login shell since \`shopt\` is not installed and"
        echo "\$0 cannot be evaluated from within this .bashrc"
    fi

    # check if module tun is available or not (it is not after system upgrade)
    modprobe tun &> /dev/null # silent output
    if [ $? -ne 0 ]; then # if not successfull either due to missing permissions or file not found
        tun_file=$(find /lib/modules/`uname -r` -print | grep -i "tun.ko")
        if [ ${#tun_file} == 0 ]; then # if missing file 
            echo "'modprobe tun' raised some problem, consider restart:"
            modprobe tun
        fi
    fi

    # check if vim/vimx is installed and supports clipboard pasting
    if check_existance vim || check_existance vimx; then
        if check_existance vim; then
            tmp=$(vim --version | grep clipboard)
            vim_clipboard=1 # default: no clipboard
            vim_xterm_clipboard=1
            if [[ "$tmp" == *"+clipboard"* ]]; then 
                vim_clipboard=0 # vim has +clipboard 
            fi
            if [[ "$tmp" == *"+xterm_clipboard"* ]]; then 
                vim_xterm_clipboard=0 # vim has +xterm_clipboard 
            fi
            if [[ $vim_clipboard == 1 ]] && [[ $vim_xterm_clipboard == 1 ]]; then
                vim_return=1 # -clipboard
            else
                vim_return=0 # +clipboard
            fi
        else
            vim_return=1 # no vim
        fi
        if check_existance vimx; then
            tmp=$(vimx --version | grep clipboard)
            vimx_clipboard=1 # default: no clipboard
            vimx_xterm_clipboard=1
            if [[ "$tmp" == *"+clipboard"* ]]; then 
                vimx_clipboard=0 # vimx has +clipboard 
            fi
            if [[ "$tmp" == *"+xterm_clipboard"* ]]; then 
                vimx_xterm_clipboard=0 # vimx has +xterm_clipboard 
            fi
            if [[ $vimx_clipboard == 1 ]] && [[ $vimx_xterm_clipboard == 1 ]]; then
                vimx_return=1 # -clipboard
            else
                vimx_return=0 # +clipboard
            fi
        else
            vimx_return=1 # no vimx
        fi
        if [[ $vim_return == 1 ]] && [[ $vimx_return == 1 ]]; then
            if check_existance vim; then
                echo warning: vim exists but with -clipboard and -xterm_clipboard
            fi
            if check_existance vimx; then
                echo warning: vimx exists but with -clipboard and -xterm_clipboard
            fi
        fi
    fi # if vim or vimx exist
   
    # check if there are cronjobs running
    if check_existance crontab; then
        printf "crontab -l ..."
        ct=$(crontab -l 2>/dev/null)
        if [[ $ct ]]; then # is set and it is not empty
            #echo ""
            #echo "$ct"
            readarray -t arr <<<$ct # split vector by \n to array
            cnt=0
            for line in "${arr[@]}"; do
                #if [[ "$line" =~ ^#.* ]]; then # starts with "#"
                if [[ "$line" != \#* && ${#line} != 0 ]]; then # starts not with "#"
                    cnt=$((cnt+1))
                    if (( $cnt == 1 )); then
                        echo
                    fi
                    echo "  active cronjob $cnt: $line"
                fi
            done
            elif [[ ! $ct ]]; then # is not set or it is set to an empty string
            printf " no active cronjob running\n"
        fi
    fi # if crontab exists
    
    # check if there are systemctl timers running
    if check_existance systemctl; then
        printf "systemctl list-timers ... "
        timers=$(systemctl list-timers) #; echo "$timers"
        readarray -t arr <<<$timers # split vector by \n to array #; echo "$arr"
        from=1
        to=${#arr[@]} #; echo "$to lines"
        to=$((to-4)) #; echo "select lines $((from+1)) to $((to+1)) ..."
        arr2=("${arr[@]:$from:$to}") #; echo "--> ${#arr2[@]} lines"
        system_services=(systemd-tmpfiles-clean.service 
                         logrotate.service
                         man-db.service
                         shadow.service
                         updatedb.service
                         motd-news.service
                         apt-daily.service
                         apt-daily-upgrade.service
                         fstrim.service
                         snapd.snap-repair.service
                         ureadahead-stop.service)
        for line in "${arr2[@]}"; do
            #echo $line
            if [[ "$line" = *" ago "* ]]; then # check if valid line
                service=${line##* } # get active service --> last component of line
                # exclude default system services
                #if [[ ${system_services[*]} =~ (^|[[:space:]])"$service"($|[[:space:]]) ]]; then # if included
                #    printf "\n  service \"$service\" is included in system_services. skip."
                if ! [[ ${system_services[*]} =~ (^|[[:space:]])"$service"($|[[:space:]]) ]]; then # if not included
                    printf "\n  systemctl status $service:"
                    status=$(systemctl status $service) #; echo "$status"
                    readarray -t arr3 <<<$status # split vector by \n to array
                    #echo "$arr3"
                    for line in "${arr3[@]}"; do
                        if [[ "$line" =~ ^"    Process: ".* ]]; then # starts with "#"
                            #echo $line
                            cmd=${line##*"ExecStart="}
                            printf "\n    $cmd"
                        fi
                    done    
                fi
            fi
        done
        echo
    fi # if systemctl exists

    # run bash stuff if available
    if ! check_existance nc-config; then
        echo nc-config is missing!
    fi
    
    # run R stuff if available
    if check_existance Rscript; then
        if check_existance mytimes.r; then
            mytimes.r
        fi
    fi
    
    # find module binary
    # $?: last command return value
    # $*: list of all args
    # works: eval `/sw/rhel6-x64/tcl/modules-3.2.10/Modules/$MODULE_VERSION/bin/modulecmd bash list`
    # works: eval `/sw/rhel6-x64/tcl/modules-3.2.10/Modules/$MODULE_VERSION/bin/modulecmd bash purge`
    # works: eval `/sw/rhel6-x64/tcl/modules-3.2.10/Modules/$MODULE_VERSION/bin/modulecmd bash load gcc`
    # $ ldd binary (executes the binary!)
    # $ readelf -d | grep NEEDED (does not execute the binary)
    if check_existance module; then
        printf "type module: "
        echo $(type module)
        modulegrep(){ # e.g. "^r/", "cdo"
            if [ $# -eq 0 ]; then
                echo "Usage: 'modulegrep cdo' or 'modulegrep ^r/' will run 'module avail -t 2>&1 | grep -i \$1'"
            else
                #echo "run 'module avail -t 2>&1 | grep -i $1'"
                module avail -t 2>&1 | grep -i $1
            fi
        }
        echo "defined modulegrep()"
        echo "loaded startup modules:"; module list
    else
        echo "module command is not set"
    fi
    
    # link dotfiles-repo functions to bin
    fs=(
        diff_filelists.r diff_namelists.r
        psme cpu cpuall cpu_total mem scpd 
        rnohup mnohup nclnohup 
        checkall 
        myfinger.r finduser.r 
        get_timestep.r get_energy.r 
        slurm_wait slurm_check.r
        esm_check_err.r esm_get_output.r echam_get_mvstreams_from_atmout.r
        esm_get_esm_version_exp esm_get_esm_version_home 
        mycdoseasmean.r mycdoseassum.r mycdotrend.r mycdoeof.r
        mycat_areadepth mycat_time.r mycat_time_depth mycat_time_depth_lat.r mycat_time_depth.r
        myeof.r plotmyeof.r
        myncrcat.r
        inertial.r
        )
    mkdir -p ~/bin
    for f in "${fs[@]}"; do
        if [ -f ~/dotfiles/functions/$f ]; then
            if [ ! -f ~/bin/$f ]; then
                echo "ln -s ~/dotfiles/functions/$f ~/bin/$f ..."
                ln -s ~/dotfiles/functions/$f ~/bin/$f
            fi
        fi
    done
   
    # slurm specific stuff
    if [ -f ~/dotfiles/functions/slurm_jobid_autocomplete.sh ]; then
        source ~/dotfiles/functions/slurm_jobid_autocomplete.sh
        if check_existance scontrol; then
            echo "activate slurm jobid autocomplete for scontrol and scancel"
            complete -F _cluster_jobs scontrol
            complete -F _cluster_jobs scancel
            if check_existance slurm_wait; then
                echo "activate slurm jobid autocomplete for slurm_wait"
                complete -F _cluster_jobs slurm_wait
            fi
        fi
    fi
    if check_existance squeue; then
        sme() { squeue -u $(whoami) ; }
        smi() { squeue -u $(whoami) -i 1 ; }
    fi
    if check_existance scontrol; then
        smee() {
            if [ -z "$1" ]; then
                echo "> smee <jobid>"
            else 
                scontrol show jobid -dd $1
            fi
        }
    fi

    # esm_master specific stuff
    if check_existance esm_master; then
        recomp_recom() {
            if [ -d ~/esm/awicm-1.0-recom ]; then 
                if command -v host &> /dev/null; then
                    hostname=$(host $(hostname)) # ollie1.awi.de has address 172.18.20.82
                    hostname=$(echo $hostname | cut -d' ' -f1)
                else
                    hostname=$(hostname)
                fi
                msg="$(date): recom+fesom recompile finished on $hostname"
                # must be in parent path of awicm-1.0
                owd=$(pwd)
                echo; echo "cd ~/esm"
                cd ~/esm
                echo "esm_master recomp-awicm-1.0-recom/recom"; echo
                esm_master recomp-awicm-1.0-recom/recom
                echo; echo "esm_master recomp-awicm-1.0-recom/fesom"; echo
                esm_master recomp-awicm-1.0-recom/fesom
                if command -v zenity &> /dev/null; then # inform via small zenity GUI alert
                    zenity --info --text="$msg"
                else # inform just in terminal
                    echo "program zenity not found"
                    echo $msg
                fi
                echo "cd $owd"
                cd $owd
            else
                echo "directory ~/esm/awicm-1.0-recom not found"
            fi
        } # recomp_recom()
    fi # if esm_master exists

    # recom stuff
    recom_normalize_nml() {
        fout=$(basename $1)
        cp $1 $fout
        sed -i 's/d0/0/' $fout # d0 --> 0
        sed -i 's/1\.d-/1e-/' $fout # 1.d- --> 1e-
        sed -i '/^[[:space:]]*$/d' $fout # rm white spaces
    }

    # load private stuff at the end to overwrite defaults (and conda) from above
    if [ -f ~/.myprofile ]; then
        printf '%*s' "$ncol" | tr ' ' "-"
        printf " ~/.myprofile "
        printf '%*s' "$ncol" | tr ' ' "-"
        echo ""
        source ~/.myprofile
    fi

    # Finish
    printf '%*s' "$ncol" | tr ' ' "*"
    printf " ~/.bashrc finish "
    printf '%*s' "$ncol" | tr ' ' "*"
    echo ""

#fi # interactive or not

