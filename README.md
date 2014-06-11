# Caliph

Caliph - a Ruby tool for generating and executing command-line commands.

Does your Ruby script or app need to generate commands to run at the CLI, to run with system() or similar?  Want to generate them in a clean, testable Ruby api? How about automatically capturing output, exit code, and other goodies?

The first version of these classes were originally written as part of Mattock by Judson Lester:  https://github.com/nyarly/mattock

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

### See the commands

`Caliph::CommandLine#string_format` or `#to_s` returns the entire command.  `Caliph::CommandLine#command` returns just the command portion without prepended environment variables, which might be handy if you're passing the command to ssh or sudo and need to handle ENV differently.

    command = cmd('java', 'my_file.jar')
    command.env['JAVA_HOME'] = '~/java_files'

    # outputs "JAVA_HOME='~/java_files' java my_file.jar"
    command.string_format   # or .to_s

    # outputs "java my_file.jar"
    command.command


### Chaining commands

`Caliph::CommandChain` and related classes implement chained commands.  If you've mixed in Caliph::CommandLineDSL, you can use operators &, |, and - for conditional, pipe, and path-chaining, respectively.

    # Pipe Chain
    # find . -name '*.sw.' | xargs rm
    cmd('find', '.', "-name '*.sw.'") | cmd('xargs', 'rm')


    # && - style conditional chain
    # cd /tmp/trash && rm -rf *
    cmd("cd", "/tmp/trash") & %w{rm -rf *}

    # Double-hyphen separated commands
    # sudo -- gem install bundler
    cmd("sudo") - ["gem", "install", "bundler"]

### Redirecting Output

    # redirect STDOUT
    # echo "foo" 1>some_file.txt
    cmd('echo').redirect_stdout('some_file.txt')

    # redirect STDERR
    # echo "foo" 2>error_file.txt
    cmd('echo').redirect_stderr('error_file.txt')

    # chain redirects
    # curl http://LRDesign.com 1>page.html 2>progress.txt
    cmd('curl', 'http://LRDesign.com').redirect_stdout('page.html').redirect_stdin('progress.txt')

    # redirect STDOUT and STDERR to the same destination with one command
    # rm -rf 1>/dev/null 2>/dev/null
    cmd('rm', '-rf').redirect_both('/dev/null')

### Execute commands and capture the output

Several instance methods are provided for running commands.

* `#execute` Run the command and wait for the result.  Returns a `CommandRunResult` instance.
* `#replace_us`  Run the command in a new process and kill this process.
* `#spin_off` Run the command as a new background process.  It can continue even if the caller terminates.
* `#background` Run the command as a background process, but kill it if the caller terminates


### Examine the results of a command

`Caliph::CommandLine#execute` returns a `Caliph::CommandRunResult` instance.  `CommandRunResult` has the following useful instance methods:

* `#stdout` A String containing the contents of STDOUT.
* `#stderr` A String containing the contents of STDERR.
* `#exit_code` The exit code of the command
* `#succeded?` True if `exit_code` is 0.
* `#must_succeed!` Calls `fail` with an error message if the command did not exit successfully.



