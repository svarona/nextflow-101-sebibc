#!/usr/bin/env nextflow

/*
 * Use echo to print 'Hello World!' to a file
 */
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