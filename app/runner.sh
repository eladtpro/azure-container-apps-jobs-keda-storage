#!/bin/bash

cwd_dir=$1
downloaded_file=$2
modules_source=$3

echo "creating directory cwd_dir: $cwd_dir"
mkdir -p $cwd_dir
cd $cwd_dir
pwd
echo "copying modules to cwd_dir from $modules_source"
cp -r $modules_source/* $cwd_dir
tofu init -upgrade
echo "running tofu plan -var-file=$downloaded_file"
tofu plan -var-file $downloaded_file # terraform.tfvars
tofu apply -auto-approve -var-file $downloaded_file