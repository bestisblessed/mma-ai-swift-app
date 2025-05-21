#!/bin/bash

sudo systemctl restart nginx
sudo systemctl restart flaskapp

sudo systemctl status nginx
sudo systemctl status flaskapp
