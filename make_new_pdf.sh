#!/bin/bash
# korolev-ia [at] yandex.ru
# version 1.0 2016.11.09
##############################

# parameters:
# $0 initial_pdf rigde.pdf
TMP_DIR="/tmp"
LOG="/opt/pdf-cutting/var/${0}.log"
DPI=300
DEBUG=1

PDF_FILE=$1
RIDGE=$2
PAGE_COUNT=`/usr/bin/pdfinfo -meta $PDF_FILE  | grep ^Pages: | sed 's/^Pages: *//'`

sleep 1
DT=`date +%s`
#DT=`date +%Y-%m-%d_%H:%M:%S`
PDF_OUTPUT="${TMP_DIR}/${DT}_RESULT.pdf"
PDF_PAGE_FIRST="${TMP_DIR}/${DT}_FIRST.pdf"
PDF_PAGE_LAST="${TMP_DIR}/${DT}_LAST.pdf"
IMG_PAGE_FIRST="${TMP_DIR}/${DT}_FIRST.png"
IMG_PAGE_LAST="${TMP_DIR}/${DT}_LAST.png"
RIDGE_RESIZED="${TMP_DIR}/${DT}_RIDGE.png"


w2log() {
	DATE=`date +%Y-%m-%d_%H:%M:%S`
	if [ "x$DEBUG" == "x1" ]; then
		echo "$DATE $1"
	fi
		echo "$DATE $1" >> $LOG
	return 0
}

do_exit() {
	rm $PDF_PAGE_FIRST $PDF_PAGE_LAST $IMG_PAGE_FIRST $IMG_PAGE_LAST $RIDGE_RESIZED &1>/dev/null 2>&1
	if [ $1 -ne 0 ]; then
		echo
		rm $PDF_OUTPUT
	fi	
	exit $1 
}


get_size() {
	WIDTH=`identify $1 | awk '{print $3}' | sed 's/x[0-9][0-9]*$//'`
	HEIGHT=`identify $1 | awk '{print $3}' | sed 's/^[0-9][0-9]*x//'`
	return 0
}


/usr/bin/pdfseparate $PDF_FILE -f 1 -l 1 $PDF_PAGE_FIRST
		if [ $? -ne 0 ]; then
			w2log	"Cannot cut first page from file '$PDF_FILE'"
			do_exit	1
		fi

/usr/bin/pdfseparate $PDF_FILE -f $PAGE_COUNT -l $PAGE_COUNT $PDF_PAGE_LAST
		if [ $? -ne 0 ]; then
			w2log	"Cannot cut last page from file '$PDF_FILE'"
			do_exit	1
		fi

		

convert -units PixelsPerInch -density $DPI $PDF_PAGE_FIRST -units PixelsPerInch -density $DPI $IMG_PAGE_FIRST
		if [ $? -ne 0 ]; then
			w2log	"Cannot convert file '$PDF_PAGE_FIRST' to '$IMG_PAGE_FIRST'"
			do_exit	1
		fi
convert -units PixelsPerInch -density $DPI $PDF_PAGE_LAST  -units PixelsPerInch -density $DPI $IMG_PAGE_LAST
		if [ $? -ne 0 ]; then
			w2log	"Cannot convert file '$PDF_PAGE_LAST' to '$IMG_PAGE_LAST'"
			do_exit	1
		fi

get_size $IMG_PAGE_FIRST
HEIGHT_FIRST=$HEIGHT
WIDTH_FIRST=$WIDTH

get_size $IMG_PAGE_LAST
HEIGHT_LAST=$HEIGHT
WIDTH_LAST=$WIDTH

if [ -z $HEIGHT_FIRST ]; then
			w2log	"Get incorrect heigth of '$IMG_PAGE_FIRST'"
			do_exit	1
fi
if [ $HEIGHT_FIRST != $HEIGHT_LAST ]; then
			w2log	"Heigth of '$IMG_PAGE_FIRST' is not the same for '$IMG_PAGE_LAST'"
			do_exit	1
fi

# set the width of ridge to 0.15( mm )*page_count
let RIDGE_WIDTH=" $PAGE_COUNT * 1772 / 1000 "
# summary width of output pdf
let OUTPUT_WIDTH=" $WIDTH_FIRST + $RIDGE_WIDTH + $WIDTH_LAST "
# ident for last_image
let IDENT_LAST=" $WIDTH_FIRST + $RIDGE_WIDTH "


convert $RIDGE -resize ${RIDGE_WIDTH}x${HEIGHT_FIRST}! $RIDGE_RESIZED
		if [ $? -ne 0 ]; then
			w2log	"Cannot resize image '$RIDGE' to size ${RIDGE_WIDTH}x${HEIGHT_FIRST} and save to '$RIDGE_RESIZED'"
			do_exit	1
		fi
convert -size ${OUTPUT_WIDTH}x${HEIGHT_FIRST} xc:white $IMG_PAGE_FIRST -geometry +0+0 \
	-composite $RIDGE_RESIZED  -geometry +${WIDTH_FIRST}+0 \
	-composite $IMG_PAGE_LAST -geometry +${IDENT_LAST}+0 -units PixelsPerInch -density $DPI \
	-composite $PDF_OUTPUT
		if [ $? -ne 0 ]; then
			w2log	"Cannot composite images '$IMG_PAGE_FIRST','$RIDGE_RESIZED','$IMG_PAGE_LAST' to '$PDF_OUTPUT'"
			do_exit	1
		fi

# all ok
do_exit	0

	
