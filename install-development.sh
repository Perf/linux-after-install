#!/usr/bin/env bash

set -eu

source ./lib.sh

install_atom

install_jetbrains_toolbox

install_docker_and_docker_compose

install_ctop

install_slack

install_phpstorm_url_handler

install_aws_cli

install_k8s_openlens
