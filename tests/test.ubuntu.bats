#!/bin/bash

load test_helper

@test "Ubuntu: Install" {
  run sudo apt-get install -y $PACKAGE_NAME
  [ "$status" -eq 0 ]
}

@test "Ubuntu: Uninstall" {
  run sudo apt-get remove -y $PACKAGE_NAME
  [ "$status" -eq 0 ]
}