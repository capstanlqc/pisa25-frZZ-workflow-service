# French master [fr-ZZ] batch transition

## Description

This application takes care of batch transitions in the French master workflow by modifying repository mappings in the project settings at the current and the previous/next step.

Finalizing a task (batch) will trigger the following actions:

0. check completion, if batch translation is completed then
1. current batch's translations become available in the next step (`cp omegat/project_save.tmx mapped/batch_dname.tmx`)
2. current batch's files become hidden and next files become unhidden in the current step 
3. current batch's files become unhidden in the next step

Step 3 when the current step is translation only happens when both `translation1` and `translation2` are completed.

## Caveats

* Every repo must be cloned to run check and make changes locally
* Credentials must be entered for each pull or push on repos
* Running OmegaT on the project to generate stats could be slow
* Does not foresee return of a batch to the previous step
* Changes in project settings are only effective when the user closes and re-opens the project

## Dependencies

* System: xmlstarlet==1.6.1 python==3.10 java==11
* OmegaT 5.8.0 (built from source, steps [here](https://github.com/capstanlqc/check-batch-completion/#install-omegat-580))
* Other packages: [`capstanlqc/check-batch-completion`](https://github.com/capstanlqc/check-batch-completion)

## Steps to use this script

1. Follow instructions at https://github.com/capstanlqc/check-batch-completion/ to set up that package, which are basically: clone that repo, create python virtual environment, install dependencies, install OmegaT 5.8 (see its readme for full details)
2. `cd /path/to/working/directory`
3. `gh repo clone capstanlqc/pisa25-frZZ-workflow-service`
4. Update path stored in `completion_check_approot` variable to point to `check-batch-completion` in your system
5. Update path stored in `omt_inst_dpath below` to point to the location of your OmegaT 5.8.0 installation
6. Update the content of files `steps.txt` and `batches.txt`
7. `bash pisa25-frZZ-workflow-service/move_batch_to_next_step.sh --batch "batchX" --step "stepY"`

## Simplified workflow example

The following examples do not include irrelevant project folders such as `/dictionary` and `/glossary`. `/` is the root folder of an OmegaT project.

For the purposes of this description, a simplified workflow is used including steps **translation1**, **translation2**, **reconciliation** and **verification** only.

### 0. Initial state

All OmegaT projects are empty:

```
>  tree -L 2
.
├── mapped
├── omegat
│   ├── project_save.tmx
│   └── step.txt
├── omegat.project
├── source
├── target
└── tm
```
The initial project settings for all steps point to batch zero (empty) in [pisa_2025ft_translation_common/source/ft/](https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/pisa_2025ft_translation_common.git), which means no files are available at that step.
``` 
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_common.git">
    <!-- source files -->
    <mapping local="source/" repository="source/ft/batch0_empty/" />
    <!-- .... -->
</repository>
```
Specifically the project settings of the **reconciliation** step will get translations from the `mapped` folders of the translation steps (which for the time being are empty) into `/tm/rec/T?`:
```
<!-- double translation -->
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_fr-ZZ_translation1.git">
    <mapping local="tm/rec/T1/" repository="mapped/"/>
</repository>
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_fr-ZZ_translation2.git">
    <mapping local="tm/rec/T2/" repository="mapped"/>
</repository>
```
At all other steps after reconciliation, project settings will get translations from the `mapped` folder of the previous steps (which for the time being is empty) into `/tm/auto/<previous-step>/`:
```
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_fr-ZZ_reconciliation.git">
    <!-- previous step -->
    <mapping local="tm/auto/<previous-step>/" repository="mapped/" />
</repository>  
```

### 1. `batch1` is released at **translation1** step
Translation steps' project settings are updated so that the `/source` folder maps from the `batch1` folder in [pisa_2025ft_translation_common/source/ft/](https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/pisa_2025ft_translation_common.git), which means that `batch1` is now available for translation.
```
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_common.git">
    <mapping local="source/batch1" repository="source/ft/batch1/" />
</repository>
``` 
The batch folder is re-created in the `/source` folder of the project isn't really necessary but it's handy to let the user always knows what batch they are translating.

A notification is sent to translators to download their project.  Batch `batch1` will be downloaded into the `/source/batch1`  folder of the translation projects.

When translator1 downloads the project, it will look like this: 

```
>  tree -L 2
.
├── mapped
├── omegat
│   ├── project_save.tmx
│   └── step.txt
├── omegat.project
├── source
│   └── batch1
│       ├── unit_X.xml
│       └── unit_Y.xml
├── target
└── tm
```

### 2. Translation of `batch1` is completed
When translator1 is done translating `batch1`, they must close the **translation1** project, finalize `batch1` task in the workflow service, and then open the **translation1** project again. _Iff_ all segments are translated in the batch, finalizing the task will trigger the following actions:

#### 2.1. `batch1` translations are made available for reconciliation
The working TM (file `/omegat/project_save.tmx`) of the **translation1** project is copied to `/mapped/batch1.tmx`. Files `/omegat/project_save.tmx` and `/mapped/batch1.tmx` are at this point identical in the **translation1** project. The `/mapped/batch1.tmx` file could now be downloaded from the **reconciliation** step.

#### 2.2. `batch2` is released at **translation1** step 
The **translation1** step's project settings are updated so that the `/source` folder maps from the next batch (`batch2`) folder in [pisa_2025ft_translation_common/source/ft/](https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/pisa_2025ft_translation_common.git), which means that `batch2` is now available for translation.
```
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_common.git">
    <mapping local="source/batch2" repository="source/ft/batch2/" />
</repository>
``` 
When the user closes the project, a script will delete any source files in the project (i.e. `batch1` files). When translator1 re-opens the **translation1** project, only files from `batch2` will be available for translation. 

When translator1 re-opens the **translation1** project, it will now look like this:

```
>  tree -L 2
.
├── mapped
│   └── batch1.tmx
├── omegat
│   ├── project_save.tmx
│   └── step.txt
├── omegat.project
├── source
│   └── batch2
│       ├── unit_C.xml
│       └── unit_D.xml
├── target
└── tm
```

The same applies for  the **translation2** step. 

#### 2.3. `batch1` is released at **reconciliation** step 
When `batch1` has been translated in both **translation1** and **translation2** steps, the **reconciliation** step's project settings are updated so that the `/source` folder maps from the `batch1` folder in [pisa_2025ft_translation_common/source/ft/](https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/pisa_2025ft_translation_common.git), which means that `batch1` is now available for reconciliation.
```
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_common.git">
    <!-- source files -->
    <mapping local="source/batch1" repository="source/ft/batch1/" />
    <!-- .... -->
</repository>
``` 
A notification is sent to the reconciler to download the **reconciliation** project. 

When the reconciler opens the **reconciliation** project, it will now look like this:
```
>  tree -L 2
.
├── mapped
├── omegat
│   ├── project_save.tmx
│   └── step.txt
├── omegat.project
├── source
│   └── batch1
│       ├── unit_A.xml
│       └── unit_B.xml
├── target
└── tm
    └── rec
        ├── T1
        │   └── batch1.tmx
        └── T2
            └── batch1.tmx
```


Translations for `batch1` will appear in the **reconciliation** project is like this:
![](https://imgur.com/LwLYmhr.png)

### 3. Reconciliation of `batch1` is completed
When the reconciler is done reconciling `batch1`, they must close the **reconciliation** project, finalize `batch1` task in the workflow service, and then open the **reconciliation** project again. _Iff_ all segments have a (reconciled) translation in the batch, finalizing the task will trigger the following actions:

#### 3.1. `batch1` translations are made available for verification
The working TM (file `/omegat/project_save.tmx`) of the **reconciliation** project is copied to `/mapped/batch1.tmx`. Files `/omegat/project_save.tmx` and `/mapped/batch1.tmx` are at this point identical in the **reconciliation** project. The `/mapped/batch1.tmx` file could now be downloaded from the **verification** step.

#### 3.2. `batch2` is released at **reconciliation** step 
The **reconciliation** step's project settings are updated so that the `/source` folder maps from the next batch (`batch2`) folder in [pisa_2025ft_translation_common/source/ft/](https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/pisa_2025ft_translation_common.git), which means that `batch2` is now available for reconciliation.
```
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_common.git">
    <mapping local="source/batch2" repository="source/ft/batch2/" />
</repository>
``` 
When the user closes the project, a script will delete any source files in the project (i.e. `batch1` files). When the reconciler re-opens the **reconciliation** project, only files from `batch2` will be available for reconciliation. 

When the reconciler re-opens the **reconciliation** project, it will now look like this:

```
>  tree -L 2
.
├── mapped
│   └── batch1.tmx
├── omegat
│   ├── project_save.tmx
│   └── step.txt
├── omegat.project
├── source
│   └── batch2
│       ├── unit_C.xml
│       └── unit_D.xml
├── target
└── tm
```

#### 3.3. `batch1` is released at **verification** step 
The **verification** step's project settings are updated so that the `/source` folder maps from the `batch1` folder in [pisa_2025ft_translation_common/source/ft/](https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/pisa_2025ft_translation_common.git), which means that `batch1` is now available for verification.
```
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_common.git">
    <!-- source files -->
    <mapping local="source/batch1" repository="source/ft/batch1/" />
    <!-- .... -->
</repository>
``` 
A notification is sent to the verifier to download the **verification** project. 

When the verifier opens the **verification** project, it will now look like this:
```
>  tree -L 2
.
├── mapped
├── omegat
│   ├── project_save.tmx
│   └── step.txt
├── omegat.project
├── source
│   └── batch1
│       ├── unit_A.xml
│       └── unit_B.xml
├── target
└── tm
    └── auto
        └── reconciliation
           └── batch1.tmx
```


### 4. Translation of `batch2` is completed
When translator1 is done translating `batch2`, they must close the **translation1** project, finalize `batch2` task in the workflow service, and then open the **translation1** project again. _Iff_ all segments are translated in the batch, finalizing the task will trigger the following actions:

#### 4.1. `batch2` translations are made available for reconciliation
The working TM (file `/omegat/project_save.tmx`) of the **translation1** project is copied to `/mapped/batch2.tmx`. Files `/omegat/project_save.tmx` and `/mapped/batch2.tmx` are at this point identical in the **translation1** project. The `/mapped/batch2.tmx` file could now be downloaded from the **reconciliation** step.

#### 4.2. `batch3` is released at **translation1** step 
The **translation1** step's project settings are updated so that the `/source` folder maps from the next batch (`batch3`) folder in [pisa_2025ft_translation_common/source/ft/](https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/pisa_2025ft_translation_common.git), which means that `batch2` is now available for translation.
```
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_common.git">
    <mapping local="source/batch3" repository="source/ft/batch3/" />
</repository>
``` 
When the user closes the project, a script will delete any source files in the project (i.e. `batch2` files). When translator1 re-opens the **translation1** project, only files from `batch3` will be available for translation. 

When translator1 re-opens the **translation1** project, it will now look like this:

```
>  tree -L 2
.
├── mapped
│   ├── batch1.tmx
│   └── batch2.tmx
├── omegat
│   ├── project_save.tmx
│   └── step.txt
├── omegat.project
├── source
│   └── batch3
│       ├── unit_E.xml
│       └── unit_F.xml
├── target
└── tm
```

The same applies for  the **translation2** step.

#### 4.3. `batch2` is released at **reconciliation** step 
When batch2 has been translated in both **translation1** and **translation2** steps, the **reconciliation** step's project settings are updated so that the `/source` folder maps from the `batch2` folder in [pisa_2025ft_translation_common/source/ft/](https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/pisa_2025ft_translation_common.git), which means that `batch2` is now available for reconciliation.
```
<repository type="git" url="&DOMAIN;/pisa_2025ft_translation_common.git">
    <!-- source files -->
    <mapping local="source/batch2" repository="source/ft/batch2/" />
    <!-- .... -->
</repository>
``` 

When the reconciler re-open the **reconciliation** project, it will now look like this:
```
>  tree -L 2
.
├── mapped
├── omegat
│   ├── project_save.tmx
│   └── step.txt
├── omegat.project
├── source
│   └── batch2
│       ├── unit_C.xml
│       └── unit_D.xml
├── target
└── tm
    └── rec
        ├── T1
        │   ├── batch1.tmx
        │   └── batch2.tmx
        └── T2
            ├── batch1.tmx        
            └── batch2.tmx
```

Batch transitions after verification are just like the translation from reconciliation to verification.

And so on and so forth :=)

### 5. Repetitions across batches
Matches for repeated segments that appear in both batches will appear only once if the translation hasn't changed. However, if the translation of the repeated common segment has changed between batches, the reconciler will see one match for each different translation. Like so:
![](https://imgur.com/xjtiLJl.png)

----------