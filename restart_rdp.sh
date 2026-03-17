#!/bin/bash
systemctl --user daemon-reload
systemctl --user restart gnome-remote-desktop.service
