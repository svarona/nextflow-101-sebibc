process SAY_HELLO {
    input:
    val name

    output:
    path '*_output.txt', emit: results

    script:
    """
    echo "Hello ${name}!" > ${name}_output.txt
    """
}

process ALL_GREETINGS {
    input:
    val names

    output:
    path 'all_greetings.txt', emit: group_results

    script:
    """
    echo "Hello ${names.join(', ')}!" > all_greetings.txt
    """
}

workflow CREATE_GREETINGS{
    take:
    name

    main:
    // Filter names with length shorter than 2 characters
    filtered_names = name
      .filter { names -> names.size() >= 2 }


    // Create one greeting for each name in the input channel
    SAY_HELLO(filtered_names)
    filtered_names.collect().view { names -> "Collected names: ${names}" }
    ALL_GREETINGS(filtered_names.collect())

    emit:
    greeting_files = SAY_HELLO.out.results
    group_greetings = ALL_GREETINGS.out.group_results
}


workflow {
    main:
    // Create a channel from the input parameter
    println "Input parameter: ${params.input}"
    input_ch = channel
        .fromPath(params.input)
        .splitText()
        .map { it.trim() }
    input_ch.view { input -> "Input channel: ${input}" }

    // Emit a greeting
    CREATE_GREETINGS(input_ch)

    publish:
    // Publish the greeting(s) file(s)
    greeting_files = CREATE_GREETINGS.out.greeting_files
    group_file = CREATE_GREETINGS.out.group_greetings
}

output {
    greeting_files {
        path 'greeting_files'
        mode 'copy'
    }
    group_file {
        path 'group_greetings'
        mode 'copy'
    }
}