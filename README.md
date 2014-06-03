# Caliph

Caliph - TDD-suitable Ruby tool for generating command-line commands via an OOP interface.

Does your Ruby script or app need to generate commands to run at the CLI, to run with system() or similar?  Want to generate them in a clean, testable Ruby api? How about automatically capturing output, exit code, and other goodies?

These classes were originally writtenas part of Mattock by Judson Lester:  https://github.com/nyarly/mattock

## Usage Examples

### Create a command

    # 'ls -la'
    Caliph::CommandLine.new('ls', '-la')

    # 'ls -la', another way
    cmd = Caliph::CommandLine.new('ls')
    cmd.options << '-la'

### Mix in Caliph::CommandLineDSL for abbreviated syntax

    include Caliph::CommandLineDSL

    # synonymous with Caliph::CommandLine.new('cat', '/etc/passwd')
    cmd('cat', '/etc/passwd')

### Add environment variables


    # RAILS_ENV=production rake db:migrate
    command = cmd('rake', 'db:migrate')
    command.env['RAILS_ENV'] = 'production


### Output with environment variables

Convert the command to a string  with `string_format`

    command = cmd('java', 'my_file.jar')
    command.env['JAVA_HOME'] = '~/java_files'

    # outputs "JAVA_HOME='~/java_files' java my_file.jar"
    command.string_format

### Output without environment variables

You might need to exclude the environment variables and pass them elsewise, if for example you are executing this command over ssh.  The method `command` produces just the command and arguments without prepending env.

    command = cmd('java', 'my_file.jar')
    command.env['JAVA_HOME'] = '~/java_files'

    # outputs "java my_file.jar"
    command.command

### Chaining of commands

`Caliph::CommandChain` and related classes implement chained commands, including operators &, |, and - for conditional, pipe, and path-chaining.

#### Pipe Chain

    # find . -name '*.sw.' | xargs rm
     cmd('find', '.', "-name '*.sw.'") | cmd('xargs', 'rm')

#### Conditional Chain

Ruby operator `&` produces a command-line and-chain with `&&`

    # cd /tmp/trash && rm -rf *
    cmd("cd", "/tmp/trash") & %w{rm -rf *}

#### double-hyphen separator

Ruby operator `-` produces a command-line path-chain with `--`

    # sudo -- gem install bundler
    cmd("sudo") - ["gem", "install", "bundler"]

### Redirect Output

TODO
