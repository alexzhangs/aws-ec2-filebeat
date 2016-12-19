#!/bin/bash -e

[[ $DEBUG -gt 0 ]] && set -x || set +x

BASE_DIR="$(cd "$(dirname "$0")"; pwd)"
PROGNAME=${0##*/}

usage () {
    printf "Install Filebeat on AWS EC2 instance.\n\n"

    printf "$PROGNAME\n"
    printf "\t[-f RPM_PATH | RPM_URL]\n"
    printf "\t[-r REPO_URL]\n"
    printf "\t[-n REPO_NAME]\n"
    printf "\t[-v VERSION]\n"
    printf "\t[-h]\n\n"

    printf "OPTIONS\n"
    printf "\t[-f RPM_PATH | RPM_URL]\n\n"
    printf "\tRPM package PATH or URL, -v VERSION is ignored with -f.\n\n"

    printf "\t[-r REPO_URL]\n\n"
    printf "\tRepo file URL.\n\n"

    printf "\t[-n REPO_NAME]\n\n"
    printf "\tRepo NAME will be enabled, all other repoes will be disabled.\n\n"

    printf "\t[-v VERSION]\n\n"
    printf "\tDefault version is determined by yum.\n\n"

    printf "\t[-h]\n\n"
    printf "\tThis help.\n\n"
    exit 255
}

install_gpg_key () {
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
}

install_yum_repo () {
    local url=$1
    curl -vL -o /etc/yum.repos.d/filebeat.repo "$url"
}


package=filebeat
additional_packages=()

while getopts f:r:n:v:h opt; do
    case $opt in
        f)
            pkg_file=$OPTARG
            ;;
        r)
            repo_file=$OPTARG
            ;;
        n)
            repo_name=$OPTARG
            ;;
        v)
            package=$package-$OPTARG
            ;;
        h|*)
            usage
            ;;
    esac
done

if [[ -n $pkg_file ]]; then
    yum install -y "$pkg_file"
else
    if [[ -n $repo_file ]]; then
        install_gpg_key
        install_yum_repo "$repo_file"
    fi

    if [[ -n $repo_name ]]; then
        yum install --disablerepo=* --enablerepo=$repo_name -y "$package"
    else
        yum install -y "$package"
    fi
fi

#/sbin/service start filebeat

exit
