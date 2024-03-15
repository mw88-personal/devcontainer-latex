# Repository for building my custome VScode latex development container


## Features
* intended to be used as a devcontainer in VSCode
* TeXlive 2023, ``scheme-full``
* preconfigured chktex
* preconfigured latexindent
* git, uses host credentials by default
* ``openssh-client``, required for properly working with git. If used in vscode, shares host keychain.
* gnuplot
* bash with oh-my-posh for better shell
* prerequistites for ``minted`` package installed, i.e. python, pygmentize

## Usage

## Build instructions
Build using ``-t`` to tag the image as **devcontainer-latex:0.9.0** (Name should be changed later).
~~~cmd
 docker buildx build  . -t devcontainer-latex:0.9.0
~~~
* ``buildx`` is necessary to use the docker buildkit, which enables the usage of heredoc syntax for cleaner multiline commands.

For debugging, you can run the container and enter an interactive shell session:
~~~cmd
docker run -it --rm devcontainer-latex:0.9.0 /bin/bash
~~~

After building, upload the new image:
~~~cmd
docker image push noctuidus/devcontainer-latex:0.9.0
~~~
where ``noctuidus`` is the docker username.


# (temporary) Notes and thoughts
* ultimately, I want to use DockerHub or another online registry to distribute my image
* must force myself to reduce usage of RUN
* include git into final container: according to https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials, vscode dev containers shares the **host** ``.gitconfig`` into the containers. The documentation says "copies", but my testing showed, that it is actually shared. However, from inside the dev container, there is only read access to the **global** git configuration.  I have tested with the global ``.gitconfig`` and a local per-project override and it seemed to work.
    ~~~cmd
    git config --local user.name "Testing Tester"
    ~~~
    start dev container and enter bash:
    ~~~bash
    # test local configuration
    git config --local --list --show-origin
    # shows:
    # ...
    # file:.git/config        user.name=Testing Tester

    # test global configuration
    git config  --list --global --show-origin
    # ...
    # file:/root/.gitconfig   user.name=Marc Weber
    # ...
    ~~~
    Reset the local change after testing from inside **or** outside container
    ~~~bash
    git config --local --unset user.name
    ~~~
    close the container and test the updated git config on **host**:
    ~~~cmd
    git config --local --list --show-origin
    # does not show a line for user.name:
    ~~~
    I keep the mounting point in the docker-compose file as instructions on how to mount the global host .gitconfig from a custom location.


# SSH agent
## Install SSH agent on windows client
~~~powershell
# as administrator
# Make sure you're running as an Administrator
Set-Service ssh-agent -StartupType Automatic
Start-Service ssh-agent
Get-Service ssh-agent
~~~
## Configure SSH agent
https://superuser.com/a/1631971/390394
