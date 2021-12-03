#!/usr/bin/env zsh

_direnv_hook_enabled=1
_direnv_hook() {
    if [ $_direnv_hook_enabled == "1" ]; then
        eval "$(direnv export bash)"
    fi
};

direnv-stop() {
    pushd $(pwd) > /dev/null
    cd
    _direnv_hook_enabled=0
    eval "$(direnv export bash)"
    popd > /dev/null
}
direnv-start() {
    echo "direnv: enabling shell hook"
    _direnv_hook_enabled=1
}

direnv-stop
rm -rf errors.log
nix run --print-build-logs
direnv-start
