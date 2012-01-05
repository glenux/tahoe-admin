#!/bin/sh
TAHOE_ROOT=/home/tahoe-lafs

if [ -d $TAHOE_ROOT/tahoe-introducer ]; then
	tahoe stop -d $TAHOE_ROOT/tahoe-introducer
fi
tahoe stop -d $TAHOE_ROOT/tahoe-node
tahoe stop -d ~/.tahoe

if [ -d $TAHOE_ROOT/tahoe-introducer ]; then
	tahoe start -d $TAHOE_ROOT/tahoe-introducer
fi
tahoe start -d $TAHOE_ROOT/tahoe-node
tahoe start -d ~/.tahoe
