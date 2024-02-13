#!/bin/bash
(sleep 5 &&
export DISPLAY=:0
desktop_resolution=$(wmctrl -d | awk ' { if ($2 == "*") print $9}')
window_resolution=$(xwininfo -name "auto-mcs" | grep 'geometry' | awk '{print $2}' | cut -d '+' -f1)
if [ "$desktop_resolution" != "$window_resolution" ]
then
    fluxbox-remote 'MaximizeWindow'
fi) &
/bad/auto-mcs