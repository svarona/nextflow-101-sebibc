# nextflow-101-sebibc

Nextflow 101 workshop for the II SEBIBC Congress 2026

This is a simplified 60 minutes workshop to get started with Nextflow, designed for the II SEBIBC Congress in 2026.

All the scripts that will be used or created during the training are available in the [`scripts/`](./scripts/) folder.

[Here](https://docs.seqera.io/nextflow/?__hstc=247481240.ccb52e68b4484858da3c13c7629ef9f4.1793699689260.1793699689260.1793704847541.2&__hssc=247481240.1.1793704847541&__hsfp=5114929bcbc4071300a47f18b670c9fc) you can find the official Nextflow documentation if you need to go deeper into it.

## Set-up

For this workshop we will need Nextflow >= 25.10.2 and any of Singularity, docker or conda.

In the workshop we will be using **micromamba** for training purposes as it is quicker and easier to install.

### Micromamba installation

You can follow the official documentation [here](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html)

### nf-core tools installation

We will be installing Nextflow and the nf-core tools through micromamba.

You can follow the official installation documentation [here](https://nf-co.re/docs/nf-core-tools/cli/installation)

```
micromamba create --name nf-core-env nf-core nextflow
micromamba activate nf-core-env
nf-core --version
nextflow -version
```

> Note: This training has been designed with `nf-core/tools version 4.2.1` and `Nextflow version 26.10.4`

## Hellow world mini-script

This is a minimum nextflow script modified from the official nextflow training [here](https://github.com/nextflow-io/training/blob/master/hello-nextflow/hello-greeetings.nf).

```bash
process SAY_HELLO {

    output:
    path 'output.txt'

    script:
    """
    echo 'Hello World!' > output.txt
    """
}

workflow {

    main:
    // emit a greeting
    SAY_HELLO()
}
```

We can just execute the script as follows:

```bash
nextflow run scripts/min-hello-greeetings.nf
```

We will see something like this:

```bash
Nextflow 26.10.5 is available - Please consider updating your version to it

 N E X T F L O W   ~  version 26.10.4

Launching `scripts/min-hello-greeetings.nf` [condescending_ramachandran] revision: f6990be1ea

executor >  local (1)
[aa/b73289] SAY_HELLO [100%] 1 of 1 ✔
```

Podemos ver el contenido de la carpeta work (el hash de la carpeta work varía de un run a otro)

```bash
ls -a work/aa/b73289*
cat work/aa/b73289*/.command.sh
cat work/aa/b73289*/output.txt
```

Output files:
- `.command.begin`: Sentinel file created by nextflow. It's empty.
- `.command.err`: Standard error
- `.command.log`: Standard error and standard output in logical order as they came out.
- `.command.out`: Standard output
- `.command.run`: What Nextflow actually executes. Depends depending if you are running it locally or in SLRUM.
- `.command.sh`: The generated script which come from the process. The `.command.run` file executes this file.
- `.exitcode`: Captures the exit code from the task. Hopefully 0 as succesfull task. Usefull to understand what is going on when you run out of memory or something else happend.
- `output.txt`: The main output from the process.

## Greetings complete-script

### Overview

This example introduces the fundamental concepts of Nextflow by building a simple workflow that generates greeting messages from a list of names.

The workflow demonstrates how to:

1. Receive input parameters and create channels.
2. Filter and transform channel elements using operators.
3. Define processes to execute individual computational tasks.
4. Connect processes through channels.
5. Collect channel elements into a single list.
6. Organise and publish workflow outputs.

The example uses two processes:

- `SAVE_GREETINGS`: generates one text file per greeting.
- `COLLECT_GREETINGS`: collects all greetings into a single text file.

### Entry workflow

The entry workflow is the main execution point of the pipeline. It creates the input channel, invokes the named workflow and defines which results should be published.

#### Creating the input channel

The workflow receives a comma-separated list of names through the `params.input` parameter.

```groovy
println "Input names: ${params.input}"

names_ch = channel.fromList(
    params.input.split(',').collect { it.trim() }
)
```

This expression uses several Groovy and Nextflow features:

- `params.input`: accesses the workflow input parameter.
- `println`: prints the input parameter directly to the console.
- `split(',')`: splits the input string into individual names.
- `collect { it.trim() }`: removes leading and trailing whitespace from each name using the Groovy `collect()` method.
- `channel.fromList()`: creates a channel emitting each element of the supplied list as an individual emission.

For example, the input:

```bash
--input 'Alice, Bob, Charlie'
```

produces a channel with three individual emissions:

```text
Alice
Bob
Charlie
```

#### Inspecting the input channel

```groovy
names_ch.view { "Input name: $it" }
```

This prints the names received by the workflow, allowing us to verify the initial input data.

#### Invoking the workflow: CREATE_GREETINGS

```groovy
CREATE_GREETINGS(names_ch)
```

The input channel is passed to `CREATE_GREETINGS`, which performs the filtering, transformation and process execution steps.

A **workflow** defines how processes and channels are connected to create a complete computational pipeline.

The named workflow `CREATE_GREETINGS` receives a channel containing individual names and performs the following operations.

##### Workflow inputs: `take:`

The `take:` section declares the inputs required by the workflow.

In this example, the workflow receives `names`, a channel containing individual names.

##### Filtering channel elements: `filter`

The `filter` operator selects the elements that satisfy a given condition.

```groovy
filtered_names = names
    .filter { name -> name.size() > 1 }
```

In this example, names containing only one character are removed from the channel.

##### Transforming channel elements: `map`

The `map` operator transforms each channel element into a new value.

```groovy
greetings = filtered_names
    .map { name -> "Hello ${name}!" }
```

Each remaining name is converted into a greeting message.

For example:

| Input | Output |
|---|---|
| Alice | Hello Alice! |
| Bob | Hello Bob! |
| Charlie | Hello Charlie! |

##### Inspecting channel contents: `view`

The `view` operator prints channel elements to the console.

```groovy
greetings.view { "Greetings: $it" }
```

This is particularly useful for debugging workflows and checking the values flowing through channels.

The `view` operator does not modify or consume the channel, so its elements remain available to downstream operations.

##### Collecting channel elements: `collect`

The Nextflow `collect` operator gathers all elements emitted by a channel into a single list.

```groovy
all_greetings = greetings.collect()
all_greetings.view { "All greetings: $it" }
```

This changes the structure of the data flowing downstream:

- Before `collect`: individual greeting strings are emitted by the channel.
- After `collect`: a single list containing all greeting strings is emitted.

The resulting list is passed to `COLLECT_GREETINGS`.

**Key concept:** `collect` changes the data structure received downstream, from individual channel elements to a single collection.

**Note:** In the input channel creation expression, `collect { it.trim() }` is a Groovy list method that transforms each list element. It is different from the Nextflow channel operator `collect()`, which gathers all channel emissions into a single list.

##### Executing processes

In Nextflow, a **process** defines a computational task. It specifies the inputs required, the outputs generated and the commands to execute.

###### SAVE_GREETINGS

The `SAVE_GREETINGS` process is invoked with the `greetings` channel:

```groovy
SAVE_GREETINGS(greetings)
```

Each channel element triggers an independent process execution. Therefore, if the channel contains three greetings, Nextflow launches three tasks. This process receives a single greeting as input and writes it into an individual text file.

**Input:**
- `greeting`: a string containing a greeting message.

**Output:**
- A text file named after the recipient.

For example, the input `Hello Alice!` generates the file `Alice.txt`, containing:

```text
Hello Alice!
```

The process uses a `val` input because the greeting is a value rather than a file. The `path` output declaration specifies the files generated by the task. The `*.txt` pattern allows Nextflow to capture the generated text file.

The `emit` option assigns the name `result` to this process output, making it accessible through `SAVE_GREETINGS.out.result`.

###### COLLECT_GREETINGS

Unlike `SAVE_GREETINGS`, this process receives the complete list containing all the greeting messages as a single input value and writes them into a single text file. Therefore, it executes only once, regardless of the number of greetings in the list.

```groovy
COLLECT_GREETINGS(all_greetings)
```

**Input:**
- `greetings`: a list of strings containing all generated greetings.

**Output:**
- `all_greetings.txt`: a file containing all greetings, one per line.

For example:

```text
Hello Alice!
Hello Bob!
Hello Charlie!
```

The process uses `greetings.join('\n')` to concatenate all greetings into a single string separated by newline characters. The `printf` command writes this string into `all_greetings.txt`, adding a newline after each greeting.

##### Workflow outputs: `emit:`

The `emit:` section exposes the outputs generated by the named workflow.

```groovy
emit:
individual_files = SAVE_GREETINGS.out.result
collected_file = COLLECT_GREETINGS.out.result
```

The outputs are assigned descriptive names so they can be accessed by the calling workflow.

#### Publishing workflow outputs: `publish:`

The `publish:` section selects the outputs from the entry workflow that should be made available to the user.

```groovy
publish:
greeting_files = CREATE_GREETINGS.out.individual_files
all_greetings_file = CREATE_GREETINGS.out.collected_file
```

The two outputs are given descriptive names:

- `greeting_files`: individual greeting files.
- `all_greetings_file`: the file containing all greetings.

### Workflow outputs

The top-level `output {}` block configures how the published results are organised.

```groovy
output {
    greeting_files {
        path 'individual_greetings'
        mode 'copy'
    }

    all_greetings_file {
        path 'all_greetings'
        mode 'copy'
    }
}
```

Each published output is assigned a destination directory relative to the workflow output directory.

The `mode 'copy'` setting instructs Nextflow to copy the files into the output directory rather than creating symbolic links.

The resulting directory structure will be:

```text
results/
├── individual_greetings/
│   ├── Alice.txt
│   ├── Bob.txt
│   └── Charlie.txt
└── all_greetings/
    └── all_greetings.txt
```

### Running the workflow

#### No input run

The script is stored inside `scripts/hello-greeetings.nf` folder, so it is executed as follows: 

```bash
nextflow run scripts/hello-greeetings.nf
```

And we will see something like this:

```bash
Nextflow 26.10.5 is available - Please consider updating your version to it

 N E X T F L O W   ~  version 26.10.4

Launching `scripts/hello-greeetings.nf` [stupefied_elion] revision: e9c721484b

WARN: Access to undefined parameter `input` -- Initialise it to a default value eg. `params.input = some_value`
ERROR ~ Cannot invoke method split() on null object

 -- Check script 'scripts/hello-greeetings.nf' at line: 129 or see '.nextflow.log' file for more details
```

If we don't specify any input, as there's no default input in the code (we could have add it, but we didn't in this example), the pipeline crashes.

#### Default run

The script is stored inside `scripts/hello-greeetings.nf` folder, so it is executed as follows: 

```bash
nextflow run scripts/hello-greeetings.nf --input 'Alice,C,Bob,A,Charlie'
```

We will see something like this:

```bash
Nextflow 26.10.5 is available - Please consider updating your version to it

 N E X T F L O W   ~  version 26.10.4

Launching `scripts/hello-greeetings.nf` [silly_knuth] revision: e9c721484b

Input names: Alice,C,Bob,A,Charlie
[-        ] CREATE_GREETINGS:SAVE_GREETINGS    [  0%] 0 of 3
[-        ] CREATE_GREETINGS:COLLECT_GREETINGS [  0%] 0 of 1
Input name: Alice
Greetings: Hello Alice!
executor >  local (4)
[d9/a12488] CREATE_GREETINGS:SAVE_GREETINGS (3) [100%] 3 of 3 ✔
[dc/5deef9] CREATE_GREETINGS:COLLECT_GREETINGS  [100%] 1 of 1 ✔
Input name: Alice
Greetings: Hello Alice!
executor >  local (4)
[d9/a12488] CREATE_GREETINGS:SAVE_GREETINGS (3) [100%] 3 of 3 ✔
[dc/5deef9] CREATE_GREETINGS:COLLECT_GREETINGS  [100%] 1 of 1 ✔
Input name: Alice
Greetings: Hello Alice!
All greetings: [Hello Alice!, Hello Bob!, Hello Charlie!]
Greetings: Hello Bob!
Greetings: Hello Charlie!
Input name: C
Input name: Bob
Input name: A
Input name: Charlie

Outputs:

  /home/svarona/Repositories/nextflow-101-sebibc/results

  greeting_files:
    - individual_greetings/Bob.txt
    - individual_greetings/Alice.txt
    - individual_greetings/Charlie.txt

  all_greetings_file: all_greetings/all_greetings.txt
```

We can see that the results were saved into the `results/` folder:

```bash
results/
├── all_greetings
│   └── all_greetings.txt
└── individual_greetings
    ├── Alice.txt
    ├── Bob.txt
    └── Charlie.txt

3 directories, 4 files
```

We can read the content of the different files:

```bash
$ cat results/all_greetings/all_greetings.txt 
Hello Alice!
Hello Bob!
Hello Charlie!

$ cat results/individual_greetings/Alice.txt 
Hello Alice!
```

As we can see, this generated more folders in the `work` folder, so every process is individual and cant overlapp or override any other process:

```bash
$ tree -L 2 work/
work/
├── 3f
│   └── 722763e56d917007397c1c19837bd8
├── 6b
│   └── b205de851c4104248edcc0b056c390
├── aa
│   └── b73289c6693ce4a69cb3ab357eeda2
├── d9
│   └── a12488883b82ea3f95714466bb0859
└── dc
    └── 5deef9840b93925549dfc31b1d4f7c

11 directories, 0 files
```

#### Specify output directory

To specify a different output directory, different from `results/`:

```bash
nextflow run scripts/hello-greeetings.nf --input 'Alice,C,Bob,A,Charlie' -output-dir my_results -resume
```

Now all the files are in the `my_results/` folder and the processes were catched from the previous run:

```bash
Nextflow 26.10.5 is available - Please consider updating your version to it

 N E X T F L O W   ~  version 26.10.4

Launching `scripts/hello-greeetings.nf` [sleepy_khorana] revision: e9c721484b

Input names: Alice,C,Bob,A,Charlie
executor >  local (4)
[d9/a12488] CREATE_GREETINGS:SAVE_GREETINGS (2) [100%] 3 of 3 ✔
[dc/5deef9] CREATE_GREETINGS:COLLECT_GREETINGS  [100%] 1 of 1 ✔
Input name: Alice
Input name: C
Input name: Bob
Greetings: Hello Alice!
Input name: A
Greetings: Hello Bob!
Input name: Charlie
Greetings: Hello Charlie!
All greetings: [Hello Alice!, Hello Bob!, Hello Charlie!]

Outputs:

  /home/svarona/Repositories/nextflow-101-sebibc/my_results

  greeting_files:
    - individual_greetings/Charlie.txt
    - individual_greetings/Alice.txt
    - individual_greetings/Bob.txt

  all_greetings_file: all_greetings/all_greetings.txt
```

```bash
$ tree my_results/
my_results/
├── all_greetings
│   └── all_greetings.txt
└── individual_greetings
    ├── Alice.txt
    ├── Bob.txt
    └── Charlie.txt

3 directories, 4 files
```

## See the runs and clean

I we want to see all the nextflow runs executed we can run:

```bash
$ nextflow log
TIMESTAMP               DURATION        RUN NAME        STATUS  REVISION ID     SESSION ID                              COMMAND                                                                                              
2026-11-04 11:01:45     -               furious_moriondo -       e9c721484b      edf909ad-1c5c-45eb-9f54-8b836fec84ff    nextflow run scripts/hello-greeetings.nf                                                           
2026-11-04 11:04:28     3.2s            silly_knuth     OK      e9c721484b      2f337a89-1b78-4301-a78d-5b7c747f7e2c    nextflow run scripts/hello-greeetings.nf --input Alice,C,Bob,A,Charlie                                    
2026-11-04 11:05:19     2.7s            sleepy_khorana  OK      e9c721484b      5437c287-86cd-4768-a31f-8cf82dfbc5d7    nextflow run scripts/hello-greeetings.nf --input Alice,C,Bob,A,Charlie -output-dir my_results -resume
```

We could re-run a nextflow revisión using:

```bash
nextflow run scripts/hello-greeetings.nf --input 'Alice,C,Bob,A,Charlie' -output-dir my_results -resume sleepy_khorana
```

Or we can clean the work folders and runs just before the last run (`sleepy_khorana` in thsi example)

```bash
nextflow clean -before sleepy_khorana -f
```

## 