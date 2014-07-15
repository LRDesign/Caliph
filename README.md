# Caliph

Caliph - a Ruby tool for generating and executing command-line commands.

Does your Ruby script or app need to generate commands to run at the CLI, to
run with system() or similar?  Want to generate them in a clean, testable Ruby
api? How about automatically capturing output, exit code, and other goodies?

Because doing the system programming to accomplish all this is really kind of a
pain, we've bundled all of these into a single gem.

[![Code Climate](https://codeclimate.com/github/LRDesign/Caliph.png)](https://codeclimate.com/github/LRDesign/Caliph)
[![Build Status](https://travis-ci.org/LRDesign/Caliph.svg?branch=master)](https://travis-ci.org/LRDesign/Caliph)
[![Dependency Status](https://gemnasium.com/LRDesign/Caliph.svg)](https://gemnasium.com/LRDesign/Caliph)


## Usage Examples

```ruby
# An elaborate way to print a file listing:

shell = Caliph.new
long_listing = shell.run("ls", "-la")
if long_listing.succeeded?)
  puts long_listing.stdout
end
```

As ever, it's a contrived example, but you can see that you use {Caliph.new} to
create a shell, and then call {Caliph::Shell#run} (or it's cousins) to build and
execute commands, and then use methods on {Caliph::CommandRunResult} to examine their
status and results. Pretty simple.

### Create a command

```
# 'ls -la'
Caliph::CommandLine.new('ls', '-la')

# 'ls -la', another way
cmd = Caliph::CommandLine.new('ls')
cmd.options << '-la'

# Of course, there's a DSL
include Caliph::CommandLineDSL

# synonymous with Caliph::CommandLine.new('cat', '/etc/passwd')
cmd('cat', '/etc/passwd')
```

### Add environment variables

```
# RAILS_ENV=production rake db:migrate
command = cmd('rake', 'db:migrate')
command.env['RAILS_ENV'] = 'production
```

### Run any of the above by giving them to a shell

```
shell.run(command)

# Shell yields commands for configuration prior to running

shell.run("rake", "db:migrate") do |migrate|
  migrate.env['RAILS_ENV'] = "production"
  migrate.redirect_stdout("/tmp/prod.log")
end
```

### See commands as they'd be run

{Caliph::CommandLine#string_format} or `#to_s` returns the entire command.
{Caliph::CommandLine#command} returns just the command portion without
prepended environment variables, which might be handy if you're passing the
command to ssh or sudo and need to handle ENV differently.

```
command = cmd('java', 'my_file.jar')
command.env['JAVA_HOME'] = '~/java_files'

command.string_format # => "JAVA_HOME='~/java_files' java my_file.jar"

command.command # => "java my_file.jar"
```


### Chaining commands

{Caliph::CommandChain} and related classes implement chained commands.  If you've mixed in {Caliph::CommandLineDSL}, you can use operators &, |, and - for conditional, pipe, and path-chaining, respectively.

```
# Pipe Chain
# find . -name '*.sw.' | xargs rm
cmd('find', '.', "-name '*.sw.'") | cmd('xargs', 'rm')


# && - style conditional chain
# cd /tmp/trash && rm -rf *
cmd("cd", "/tmp/trash") & %w{rm -rf *}

# Double-hyphen separated commands
# sudo -- gem install bundler
cmd("sudo") - ["gem", "install", "bundler"]
```

### Redirecting Output

```
# redirect STDOUT
# echo "foo" 1>some_file.txt
cmd('echo').redirect_stdout('some_file.txt')

# redirect STDERR
# echo "foo" 2>error_file.txt
cmd('echo').redirect_stderr('error_file.txt')

# chain redirects
# curl http://LRDesign.com 1>page.html 2>progress.txt
cmd('curl', 'http://LRDesign.com').redirect_stdout('page.html').redirect_stderr('progress.txt')

# redirect STDOUT and STDERR to the same destination with one command
# rm -rf 1>/dev/null 2>/dev/null
cmd('rm', '-rf').redirect_both('/dev/null')
```

### Execute commands and capture the output

Several instance methods on {CommandLine} and {CommandChain} are provided for executing commands.

* `run` Run the command and wait for the result.  Returns a `CommandRunResult` instance.
* `execute` Same as `run`, but terser, with no additional output added to STDOUT.
* `run_as_replacement`  Run the command in a new process and kill this process.
* `run_detached` Run the command as a new background process.  It can continue even if the caller terminates.
* `run_in_background` Run the command as a background process, but kill it if the caller terminates

```
# find all vim swap files and wait for result
results = shell.run(cmd("find", '.', "-name *.sw.'"))

# delete all vim swap files in a parallel process
find_swaps = cmd('find', '.', "-name '*.sw.'") | cmd('xargs', 'rm')
shell.run_in_background(find_swaps)

# launch a server, terminating this process.  Useful for wrapper scripts!
launcher = cmd('pg_ctl', 'start -l', 'logfile')
shell.run_as_replacement(launcher)
```

### Examine the results of a command

{Caliph::Shell#execute} returns a {Caliph::CommandRunResult} instance.  {CommandRunResult} has the following useful instance methods:

* `stdout` A String containing the contents of STDOUT.
* `stderr` A String containing the contents of STDERR.
* `exit_code` The exit code of the command
* `succeded?` True if `exit_code` is 0.
* `must_succeed!` Calls `fail` with an error message if the command did not exit successfully.

## Testing code that uses Caliph

Caliph includes some useful classes for mocking out the command line
environment for purposes of testing. See {Caliph::MockCommandResult} and
{Caliph::CommandLine} in lib/caliph/testing for more info.

Further documentation on testing coming soon!

## Acknowledgements

The first version of these classes were originally written as part of Mattock
by Judson Lester:  https://github.com/nyarly/mattock

## Credits

Evan Dorn and Judson Lester of Logical Reality Design, Inc.
