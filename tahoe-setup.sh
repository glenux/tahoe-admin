#!/bin/sh
TAHOE_ROOT=/home/tahoe-lafs
TAHOE_HOST=
TAHOE_DIRCAP=
TAHOE_PORT=7790

TAHOE_INTRODUCER_ENABLE=yes
TAHOE_INTRODUCER_STRING=
TAHOE_INTRODUCER_ROOT=$TAHOE_ROOT/tahoe-introducer

TAHOE_NODE_ROOT=$TAHOE_ROOT/tahoe-node
TAHOE_CLIENT_ROOT=$HOME/.tahoe


##
# Handle command line
##
while [ $# -gt 0 ]
do
	case "$1" in
		-n)	TAHOE_HOST=${2:-}
			if [ -z "$TAHOE_HOST" ]; then
				echo "Error: missing hostname parameter" 1>&2
				exit 1
			fi
			shift
			;;
		-i)  
			TAHOE_INTRODUCER_STRING=${2:-}
			TAHOE_INTRODUCER_ENABLE=no
			if [ -z "$TAHOE_INTRODUCER_STRING" ]; then
				echo "Error: missing introducer string" 1>&2
				exit 1
			fi
			shift
			;;
		-d)	
			TAHOE_DIRCAP=${2:-}
			if [ -z "$TAHOE_DIRCAP" ]; then
				echo "Error: missing dircap parameter" 1>&2
				exit 1
			fi
			shift
			;;
		-h)
			echo "Usage $0 [options]"
			echo ""
			echo "Options"
			echo "-n hostname	Set node host name (mandatory)"
			echo "-i str		Set introducer string (disable local introducer)"
			echo "-h		Show this help"
			exit 0
			;;
		*)
			echo "Error: unknown parameter '$1'" 1>&2
			exit 1
			;;
	esac
	shift
done
# verify mandatory parameters
if [ -z "$TAHOE_HOST" ]; then
	echo "Error: hostname not defined (-n)" 1>&2
	exit 1
fi

##
# Cleanup
##
killall -9 tahoe
rm -fr $TAHOE_INTRODUCER_ROOT
rm -fr $TAHOE_NODE_ROOT
rm -fr $TAHOE_CLIENT_ROOT
mkdir -p $TAHOE_ROOT

if [ "$TAHOE_INTRODUCER_ENABLE" = "yes" ]; then
##
# Create & run introducer
##
tahoe create-introducer $TAHOE_INTRODUCER_ROOT
sed -i \
            -e"s/^.*tub.port.*=.*$/tub.port = $TAHOE_PORT/" \
            -e "s/^.*tub.location.*=.*$/tub.location = $TAHOE_HOST:$TAHOE_PORT,127.0.0.1:$TAHOE_PORT/" \
            $TAHOE_INTRODUCER_ROOT/tahoe.cfg
tahoe start -d $TAHOE_INTRODUCER_ROOT
fi

##
# Create & run node
##
tahoe create-node $TAHOE_NODE_ROOT
if [ "$TAHOE_INTRODUCER_ENABLE" = "yes" ]; then
	TAHOE_INTRODUCER_STRING=`cat $TAHOE_INTRODUCER_ROOT/introducer.furl`
fi
sed -i \
            -e "s/^.*nickname.*=.*$/nickname = $TAHOE_HOST/" \
            -e "s/^.*reserved_space.*=.*$/reserved_space = 10G/" \
	    -e "s|^.*introducer.furl.*=.*$|introducer.furl = $TAHOE_INTRODUCER_STRING|" \
	    -e "s/^.*web.port.*=.*$/web.port = tcp:3456:interface=127.0.0.1/" \
            $TAHOE_NODE_ROOT/tahoe.cfg
tahoe start -d $TAHOE_NODE_ROOT

##
# Create & run client
##
tahoe create-client $TAHOE_CLIENT_ROOT
sed -i \
            -e "s/^.*shares.needed.*=.*$/shares.needed = 2/" \
            -e "s/^.*shares.happy.*=.*/shares.happy = 2/" \
            -e "s/^.*shares.total.*=.*/shares.total = 3/" \
	    -e "s|^.*introducer.furl.*=.*$|introducer.furl = $TAHOE_INTRODUCER_STRING|" \
	    -e "s/^.*web.port.*=.*$/web.port = tcp:3457:interface=127.0.0.1/" \
            $TAHOE_CLIENT_ROOT/tahoe.cfg
cp $TAHOE_NODE_ROOT/node.url $TAHOE_CLIENT_ROOT/node.url
tahoe start -d $TAHOE_CLIENT_ROOT
if [ -z "$TAHOE_DIRCAP" ]; then
	tahoe create-alias tahoe
else
	tahoe add-alias tahoe $TAHOE_DIRCAP
fi

##
# Summary
##
echo " "
echo "# Summary "
echo " "
echo "Introducer = $TAHOE_INTRODUCER_STRING"
echo "Aliases ="
tahoe list-aliases

