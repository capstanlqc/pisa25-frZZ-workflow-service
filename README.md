# French master [fr-ZZ] batch transition

## Description

Finalizing a task (batch) will trigger the following actions:

0. check completion, if batch translation is completed then
1. current batch's translations become available in the next step (`cp omegat/project_save.tmx mapped/batch_dname.tmx`)
2. current batch's files become hidden and next files become unhidden in the current step 
3. current batch's files become unhidden in the next step

Step 3 when the current step is translation only happens when both `translation1` and `translation2` are completed.

# Caveats

* Every repo must be cloned to run check and make changes locally
* Credentials must be entered for each pull or push on repos
* Running OmegaT on the project to generate stats could be slow
* Does not foresee return of a batch to the previous step
* Changes in project settings are only effective when the user closes and re-opens the project

# Dependencies

* System: xmlstarlet python==3.10 java==11
* OmegaT 5.8.0 (built from source, steps here https://github.com/capstanlqc/check-batch-completion/#install-omegat-580)
* Other packages: `capstanlqc/check-batch-completion`

# Steps to use this script

1. Follow instructions at https://github.com/capstanlqc/check-batch-completion/ to set up that package, which are basically: clone that repo, create python virtual environment, install dependencies, install OmegaT 5.8 (see its readme for full details)
2. `cd /path/to/working/directory`
3. `gh repo clone capstanlqc/pisa25-frZZ-workflow-service`
4. Update path stored in `completion_check_approot` variable to point to `check-batch-completion` in your system
5. Update path stored in `omt_inst_dpath below` to point to the location of your OmegaT 5.8.0 installation
6. Update the content of files `steps.txt` and `batches.txt`
7. `bash pisa25-frZZ-workflow-service/move_batch_to_next_step.sh --batch "batchX" --step "stepY"`