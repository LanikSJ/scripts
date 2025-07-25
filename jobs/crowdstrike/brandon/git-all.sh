#!/usr/bin/env bash
# This script should be named (or symbolically linked) as git-all so that
# it can be run as a git command (if it is in the path). The repo location should
# be set in REPOLOC. Can be relative if this script is also in a repo!

# Standard bash stuff to get the current directory
unset CDPATH
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

# This should be the location of your directory that has repos in it
#REPOLOC=$DIR/..
REPOLOC=$(pwd)

# ColorStuff
txtrst=$(tput sgr0)
txtbold=$(tput bold)

# Variables for color and spawned processes
var=1
#maxvar=8
spawned=()

case ${TERM} in
  *term | rxvt | linux | screen-256color | xterm-256color | *-256color) maxvar=239 ;;
  *) maxvar=8 ;;
esac

#if [ $TERM = "xterm-256color" ] ; then maxvar=239 ; else maxvar=8 ; fi

if [[ $# = 0 ]] || [[ $1 = -h ]] ; then
    echo "${txtrst}git all [option]"
    echo "Options:"
    echo " status: Checks all the git repos in git folder"
    echo " qstatus: Checks all the git repos in git folder (no fetch)"
    echo " pull: Pulls all repos in the folder"
    echo " fetch: Fetches all repos in the folder"
    echo " qfetch: Fetches all repos in the folder (somewhat) quietly"
    echo " pfetch: Fetches all repos in the folder with the -p flag passed"
    echo " merge: Merges all repos in the folder (origin/master)"
    echo " branch: Prints branch for all repos in the folder"
    exit 0
fi

cd $REPOLOC
if [[ $1 == qfetch ]] || [[ $1 == fetch ]] || [[ $1 == status ]] || [[ $1 == branch ]]; then
    for file in $(ls); do
        if [[ -d $REPOLOC/$file/.git ]]; then
            cd $REPOLOC/$file
            git fetch -q &
            spawned+=($!)
        fi
    done

    echo -n "Waiting for all repos to report: "
    for pid in ${spawned[@]}; do
        wait $pid
    done
    echo "done"
fi

if [[ $1 == pfetch ]]; then
  for file in $(ls); do
    if [[ -d $REPOLOC/$file/.git ]]; then
      cd $REPOLOC/$file
      git fetch -p &
      spawned+=($!)
    fi
  done

  echo -n "Waiting for all repos to report: "
  for pid in ${spawned[@]}; do
    wait $pid
  done
  echo "done"
fi

cd $REPOLOC
for file in $(ls); do
    if [[ -d $REPOLOC/$file/.git ]]; then
        cd $REPOLOC/$file
        echo -n "$(tput setaf $var)${txtbold}"

        if [[ $1 == status ]] || [[ $1 == qstatus ]]; then
            echo  -n "Checking $file: "
            if git diff-index --quiet HEAD -- ; then
                if [[ -n $(git rev-list origin...HEAD) ]]; then
                    if  [[ -n $(git rev-list origin..HEAD) ]]; then
                        echo "Needs pushing:"
                        echo -n "$txtrst$(tput setaf $var)"
                        git log origin/master..HEAD --oneline
                    else
                        echo "Needs merging:"
                        echo -n "$txtrst$(tput setaf $var)"
                        git log HEAD..origin/master --oneline
                        #git rev-list HEAD..format --format="%s" --abbrev-commit
                    fi
                else
                    echo 'No changes'
                fi
            else
                echo 'Changed files:'
            fi
            echo -n "$txtrst$(tput setaf $var)"
            git status -s

        elif [[ $1 == fetch ]]; then
            echo -n "Fetched $file: "
            if [[ -n $(git rev-list HEAD..origin) ]]; then
                echo "Needs merging:"
                echo -n "$txtrst$(tput setaf $var)"
                git log HEAD..origin/master --oneline
            else
                echo 'Up to date.'
            fi

        elif [[ $1 == pfetch ]]; then
            echo -n "Fetched $file: "
            if [[ -n $(git rev-list HEAD..origin) ]]; then
                echo "Needs merging:"
                echo -n "$txtrst$(tput setaf $var)"
                git log HEAD..origin/master --oneline
            else
                echo 'Up to date.'
            fi


        elif [[ $1 == merge ]]; then
            echo -n "Merging $file: "
            cd $REPOLOC/$file
            if [[ -n $(git rev-list HEAD..origin) ]]; then
                echo "$txtrst$(tput setaf $var)"
                git merge origin/master
            else
                echo "merge not needed."
            fi

        elif [[ $1 == pull ]]; then
            echo  -n "Pulling $file: "
            cd $REPOLOC/$file
            echo -n "$txtrst$(tput setaf $var)"

            if ! git pull; then
                echo $txtrst
                exit 1
            fi
        
        elif [[ $1 == branch ]]; then
            echo -n "Repo $file is on branch: "
            echo -n "$txtrst$(tput setaf $var)"
            git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'

        else
            echo "${txtrst}Option Not found..."
            exit 1
        fi

        echo -n $txtrst

        [ $var = 6 ] && var=8
        var=$(( ( RANDOM % $maxvar ) + 1 ))
        # var=$(((var+1)%maxvar))
        # echo $var
    fi
done

