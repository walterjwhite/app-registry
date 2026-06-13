#!/bin/sh
[ $_CLEAN_GO_CACHE ] && rm -rf $HOME/.cache/go-build $HOME/.cache/goimports $HOME/.cache/golangci-lint $HOME/go/pkg
