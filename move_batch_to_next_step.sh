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
# __version__ = "0.3.0"
# __maintainer__ = "Manuel Souto Pico"
# __email__ = "manuel.souto@capstan.be"
# __status__ = "Testing"

#### description

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

# caveats:
# every repo must be cloned to check locally
# credentials must be typed for each pull or push on repos
# running omegat on the project to generate stats is a bit slow
# does not foresee return of a batch to the previous step

# Proposal: 
# start with source folder pointing to first batch folder
# <mapping local="source/batch1/" repository="source/ft/batch1/"/>
# 

# Dependencies
# ============

# system: xmlstarlet python==3.10 java==11
# omegat 5.8.0 (built from source, steps here https://github.com/capstanlqc/check-batch-completion/#install-omegat-580)
# other packages: capstanlqc/check-batch-completion 

# Steps to use this script:
# =========================

# follow instructions at https://github.com/capstanlqc/check-batch-completion/ to set up that package
# which are basically: clone the repo, create python virtual environment, install dependencies, install omegat 5.8

# cd /path/to/working/directory
# gh repo clone capstanlqc/pisa25-frZZ-workflow-service
# update path stored in completion_check_approot below to point to check-batch-completion in your system
# update path stored in omt_inst_dpath below to point to the location of your omegat 5.8.0 installation
# update the content of files steps.txt and batches.txt 
# run:
# bash pisa25-frZZ-workflow-service/move_batch_to_next_step.sh --batch "batchX" --step "stepY"

# Constants and preliminary checks
# ================================

# functions 
die() { echo ; echo "$*" 1>&2 ; echo ; exit 1; }

# constants
THIS_SCRIPT_FPATH=$(realpath "$0")
THIS_SCRIPT_DPATH=$(dirname "$THIS_SCRIPT_FPATH")
cwd=$(pwd)

# check that lists of steps and batches are there
[[ -f "$THIS_SCRIPT_DPATH/steps.txt" ]] && steps_fpath="$THIS_SCRIPT_DPATH/steps.txt" || die "👉 Kaboom: steps.txt not found"
[[ -f "$THIS_SCRIPT_DPATH/batches.txt" ]] && batches_fpath="$THIS_SCRIPT_DPATH/batches.txt" || die "👉 Kaboom: batches.txt not found"

# check arguments
[[ "$1" == "--batch" ]] || [[ "$1" == "-b" ]] || die "👉 Kaboom: --batch flag not found"
[[ "$3" == "--step" ]] || [[ "$3" == "-s" ]] || die "👉 Kaboom: --step flag not found"
[[ -z $2 ]] && die "👉 Kaboom: The current batch argument doesn't seem to be defined"
[[ -z $4 ]] && die "👉 Kaboom: The current step argument doesn't seem to be defined"

# name arguments
current_batch="$2" 				# $1 is the --batch flag
current_step_repo_dname="$4" 	# $3 is the --step flag
next_batch=$(grep -A1 $current_batch $batches_fpath | grep -v $current_batch)
# next step to be defined below if needed

# the check-batch-completion package must be installed at the following path
completion_check_approot="/home/souto/Repos/capstanlqc/check-batch-completion" # <==== update

# some logging
echo "Current step (repo name):  $current_step_repo_dname"
echo "Current batch:             $current_batch" # name of folder in source 
echo "Next batch:                $next_batch" 

# Logic
# =====

# clone the repo for current step
# credentials will be requested # @todo: save credentials in environment variables or something like that
yes | rm -r $current_step_repo_dname
git clone https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/$current_step_repo_dname
current_step_repo_dpath=$(readlink -f $current_step_repo_dname)

# make a copy to run omegat on it
current_step_omtproj_dname="${current_step_repo_dname}_omt"
cp -r $current_step_repo_dname $current_step_omtproj_dname

# path to the omegat 5.8.0 installation
omt_inst_dpath="/home/souto/Repos/omegat-org/omegat/build/install/OmegaT" # <==== update

echo "Generating statistics of the current step..."
java -jar $omt_inst_dpath/OmegaT.jar $current_step_omtproj_dname --mode=console-stats --output-file=$current_step_repo_dname/omegat/project_stats.json > /dev/null 2>&1
# the copy of the repo is not needed anymore
yes | rm -r $current_step_omtproj_dname

steps_parentdir=$(dirname $current_step_repo_dpath) # same as pwd

current_step_repo_dname_numberless=$(echo "$current_step_repo_dname" | sed -e 's/[0-9]$//g')

[[ -d "$current_step_repo_dpath" ]] || die "👉 Kaboom: $current_step_repo_dpath not found"


### @todo: current_step_repo_dpath (git) - copy current_step_repo_dpath (omegat)

# 0 check completion
# echo "Check whether the translation on batch '$current_batch' is complete"
cd $completion_check_approot && batch_completed=$(poetry run python omt_check_batch_completion.py -f $current_step_repo_dpath/omegat/project_stats.json | grep "$current_batch" | grep -c "True"); cd - > /dev/null

echo "\$batch_completed: $batch_completed"

if [[ "$batch_completed" != "1" ]]
then
	#@todo: yes | rm -r $current_step_repo_dname
	die "👉 Kaboom: '$current_batch' not completed at step '$current_step_repo_dname'"
fi

# 1 batch's translations become available for the next step
mkdir -p $current_step_repo_dpath/mapped/
cp $current_step_repo_dpath/omegat/project_save.tmx $current_step_repo_dpath/mapped/$current_batch.tmx
echo "👉 Translations of batch '$current_batch' are now ready to be mapped"

# 2 change source path in current step to point to the next batch folder
xmlstarlet edit --inplace --update "//mapping[@local='source/']/@repository" --value "source/ft/$next_batch/" $current_step_repo_dpath/omegat.project
echo "👉 The current step '$current_step_repo_dname' is ready to start batch '$next_batch'"

echo "👉 Let's commit changes to the '$current_step_repo_dname' repo..."
msg="Mapped TM for'$current_batch', changed source to '$next_batch' and updated JSON stats."
echo "👉 $msg"
cd $current_step_repo_dpath
# $current_step_repo_dpath/mapped/$current_batch.tmx
# $current_step_repo_dpath/omegat.project
# $current_step_repo_dpath/omegat/project_stats.json
git add . && git commit -m "$msg" && git push
cd $cwd

# 3 change source path in next step to point to the current batch folder

#if [[ $current_step_repo_dname =~ translation[12]$ ]]
# [[ $next_step_repo_dname = *_reconciliation ]] 
#then 
	# check whether both translations are completed
#	[[ -f "$steps_parentdir/${current_step_repo_dname_numberless}1/mapped/$current_batch.tmx" ]] || hold=1
#	[[ -f "$steps_parentdir/${current_step_repo_dname_numberless}2/mapped/$current_batch.tmx" ]] || hold=1
#fi

# if current step is translation (1 or 2)
if [[ "$current_step_repo_dname" =~ _translation[0-9]$ ]]
then

	echo "This is a translation step, let's check the other translation..."
	# get the name of the other translation repo
	[[ "$current_step_repo_dname" == *_translation1 ]] && parallel_substep=$(echo "$current_step_repo_dname" | sed -e 's/\(translation\)1$/\12/')
	[[ "$current_step_repo_dname" == *_translation2 ]] && parallel_substep=$(echo "$current_step_repo_dname" | sed -e 's/\(translation\)2$/\11/')

	echo "\$parallel_substep=$parallel_substep"

	# if the name of the other translation repo is known
	if [[ ! -z "$parallel_substep" ]]
	then
		# clone the other translation repo	
		yes | rm -r $parallel_substep; git clone https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/$parallel_substep

		# check if the current batch was finalized in the other translation repo
		[[ -f "$parallel_substep/mapped/$current_batch.tmx" ]] || hold=true
	fi
	#@todo: rm -r $parallel_substep
fi



#[[ ! -z "$parallel_substep" ]] && [[ -f "$steps_parentdir/$parallel_substep/mapped/$current_batch.tmx" ]] || hold=true

#if [[ "$hold" != true ]]
# if there's no reason to hold the workflow...
if [[ -z $hold ]]
then
	echo "👉 Translations are ready to move forward"
	
	# clone next step repo
	next_step_repo_dname=$(grep -A1 $current_step_repo_dname_numberless $steps_fpath | grep -v $current_step_repo_dname_numberless)
	echo "\$next_step_repo_dname=$next_step_repo_dname"
	[[ -z "$next_step_repo_dname" ]] || yes | rm -r $next_step_repo_dname; git clone https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/$next_step_repo_dname

	# confirm the clone exists
	next_step_repo_dpath=$(readlink -f $next_step_repo_dname)
	# next_step_repo_dpath=$steps_parentdir/$next_step_repo_dname
	echo "\$next_step_repo_dpath=$next_step_repo_dpath"
	[[ -d "$next_step_repo_dpath" ]] || die "Kaboom=$next_step_repo_dpath not found"

	# set source files to the finalized batch
	xmlstarlet edit --inplace --update "//mapping[@local='source/']/@repository" --value "source/ft/$current_batch/" $next_step_repo_dpath/omegat.project

	echo "👉 Let's commit changes to the '$next_step_repo_dname' repo..."
	msg="Changed source to '$current_batch' in step '$next_step_repo_dname'"
	echo "👉 $msg"
	cd $next_step_repo_dpath
	# $current_step_repo_dpath/mapped/$current_batch.tmx
	# $current_step_repo_dpath/omegat.project
	# $current_step_repo_dpath/omegat/project_stats.json
	git add . && git commit -m "$msg" && git push
	cd $cwd

	yes | rm -r $next_step_repo_dpath
else
	echo "👉 Batch '$current_batch' not completed at step '$parallel_substep'"
	echo "👉 Reconciliation step on hold!" 
fi


# clean up the mess
# delete current and next step repos and omtproj dirs... _omt
# rm -r $current_step_repo_dname
