#!/usr/bin/env bash

#  This script is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with cApps. If not, see <https://www.gnu.org/licenses/>.

# ############# AUTHORSHIP INFO ###########################################

# __author__ = "Manuel Souto Pico"
# __copyright__ = "Copyright 2022, cApps/cApStAn"
# __license__ = "GPL"
# __version__ = "0.2.0"
# __maintainer__ = "Manuel Souto Pico"
# __email__ = "manuel.souto@capstan.be"
# __status__ = "Testing"

# bash dependencies: xmlstarlet / pipenv jq httpie python==3.9.2 java==11 unoconv

# call this script as
# go to /path/to/Repos/ACER-PISA-2025
# bash /path/to/this/script.sh --batch foo1 --step /path/to/bar

# functions 
die() { echo "$*" 1>&2 ; exit 1; }

# constants
app_root="/home/souto/Repos/capstanlqc/check-batch-completion"
# $1 is the --batch flag
current_batch="$2"
# $3 is the --step flag
#current_step_repo_dpath="$4"
current_step_repo_dname="$4"

[[ -f "steps.txt" ]] || die "Kaboom: steps.txt not found"
[[ -f "batches.txt" ]] || die "Kaboom: batches.txt not found"

# Finalizing the task (batch) will trigger the following actions:
# 0+ check completion, if batch translation is completed then
# 1+ batch's translations become available in the next step
#	- cp omegat/project_save.tmx mapped/batch_dname.txt
# 2+ batch's files become hidden in the current step
#	- either mask batch folder, or
#	- change source path
# 3+ batch's files become unhidden in the next step
#	- either unmask batch folder, or
#	- change source path

	
# omt_proj_dpath = current_step_repo_dpath = path to omegat project dir for current step 

echo "\$current_batch=$current_batch" # name of folder in source 
next_batch=$(grep -A1 $current_batch batches.txt | grep -v $current_batch)
echo "\$next_batch=$next_batch"
echo "\$current_step_repo_dname=$current_step_repo_dname"

#@todo: if t1, then clone t2, vice versa
[[ "$current_step_repo_dname" == *_translation1 ]] && parallel_substep=$(echo "$current_step_repo_dname" | sed -e 's/\(translation\)1$/\12/') && echo "\$parallel_substep1=$parallel_substep"
[[ "$current_step_repo_dname" == *_translation2 ]] && parallel_substep=$(echo "$current_step_repo_dname" | sed -e 's/\(translation\)2$/\11/') && echo "\$parallel_substep2=$parallel_substep"

# credentials will be requested
git clone https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/$current_step_repo_dname

# make a copy for omegat
current_step_omtproj_dname="${current_step_repo_dname}_omt"
echo "\$current_step_omtproj_dname=$current_step_omtproj_dname"
cp -r $current_step_repo_dname $current_step_omtproj_dname
omt_inst_dpath="/home/souto/Repos/omegat-org/omegat/build/install/OmegaT" # 5.8.0
# wget https://raw.githubusercontent.com/kosivantsov/omegat_scripts/master/aux_scripts/headlessOmegaT
echo "java -jar $omt_inst_dpath/OmegaT.jar $current_step_omtproj_dname --mode=console-stats --output-file=$current_step_repo_dname/omegat/project_stats.json"
java -jar $omt_inst_dpath/OmegaT.jar $current_step_omtproj_dname --mode=console-stats --output-file=$current_step_repo_dname/omegat/project_stats.json
# cp $current_step_omtproj_dname/omegat/project_stats.json $current_step_repo_dname/omegat/project_stats.json

echo "\$parallel_substep=$parallel_substep"

[[ -z "$parallel_substep" ]] || git clone https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/$parallel_substep

current_step_repo_dpath=$(readlink -f $current_step_repo_dname)
echo "\$current_step_repo_dpath=$current_step_repo_dpath" # omegat project folder path

#current_step_repo_dname=${current_step_repo_dpath##*/}
# current_step_repo_dname=${current_step_repo_dname%"$suffix"}
# current_step_repo_dname=$(echo "$current_step_repo_dname" | sed -e 's/[0-9]$//g')
echo "\$current_step_repo_dname=$current_step_repo_dname"

steps_parentdir=$(dirname $current_step_repo_dpath) # same as pwd

current_step_repo_dname_numberless=$(echo "$current_step_repo_dname" | sed -e 's/[0-9]$//g')

[[ -d "$current_step_repo_dpath" ]] || die "Kaboom=$current_step_repo_dpath not found"


### @todo: current_step_repo_dpath (git) - copy current_step_repo_dpath (omegat)

# 0 check completion
cd $app_root && completed=$(poetry run python omt_check_batch_completion.py -f $current_step_repo_dpath/omegat/project_stats.json | grep "$current_batch" | grep -c "True") && cd - > /dev/null

[[ "$completed" == "1" ]] || die "Kaboom: batch traslation not completed"


# 1 batch's translations become available for the next step
mkdir -p $current_step_repo_dpath/mapped/
cp $current_step_repo_dpath/omegat/project_save.tmx $current_step_repo_dpath/mapped/$current_batch.tmx

# 2 change source path in current step to point to the next batch folder
xmlstarlet edit --inplace --update "//mapping[@local='source/']/@repository" --value "source/ft/$next_batch/" $current_step_repo_dpath/omegat.project

# @todo: push $current_step_repo_dpath/mapped/$current_batch.tmx
# @todo: push $current_step_repo_dpath/omegat.project
# @todo: push $current_step_repo_dpath/omegat/project_stats.json

# 3 change source path in next step to point to the current batch folder

#if [[ $current_step_repo_dname =~ translation[12]$ ]]
# [[ $next_step_repo_dname = *_reconciliation ]] 
#then 
	# check whether both translations are completed
#	[[ -f "$steps_parentdir/${current_step_repo_dname_numberless}1/mapped/$current_batch.tmx" ]] || hold=1
#	[[ -f "$steps_parentdir/${current_step_repo_dname_numberless}2/mapped/$current_batch.tmx" ]] || hold=1
#fi

[[ ! -z "$parallel_substep" ]] && [[ -f "$steps_parentdir/$parallel_substep/mapped/$current_batch.tmx" ]] || hold=true

if [[ "$hold" != true ]]
then
	echo "double translation ready to move forward" # clone next
	
	next_step_repo_dname=$(grep -A1 $current_step_repo_dname_numberless steps.txt | grep -v $current_step_repo_dname_numberless)
	echo "\$next_step_repo_dname=$next_step_repo_dname"
	[[ -z "$next_step_repo_dname" ]] || git clone https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/$next_step_repo_dname

	next_step_repo_dpath=$(readlink -f $next_step_repo_dname)
	# next_step_repo_dpath=$steps_parentdir/$next_step_repo_dname
	echo "\$next_step_repo_dpath=$next_step_repo_dpath"
	[[ -d "$next_step_repo_dpath" ]] || die "Kaboom=$next_step_repo_dpath not found"

	[[ "$hold" = true ]] || xmlstarlet edit --inplace --update "//mapping[@local='source/']/@repository" --value "source/ft/$current_batch/" $next_step_repo_dpath/omegat.project

	# @todo: push $next_step_repo_dpath/omegat.project
else
	echo "double translation NOT ready yet to move forward" 
fi



# delete current and next step repos and omtproj dirs... _omt