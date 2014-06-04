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
    cmd('rm', '-rf').redirect('/dev/nul')

### Execute commands and capture the output

TODO

