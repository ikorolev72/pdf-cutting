#!/bin/bash
# korolev-ia [at] yandex.ru
# version 1.2 2016.11.15
##############################


BASENAME=`basename $0`
cd `dirname $0`
DIRNAME=`pwd`

HOME_DIR="$DIRNAME/home"
SCAN_DIR="$DIRNAME/in"
FAILED_DIR="$DIRNAME/failed"
TMP_DIR="$DIRNAME/tmp"
VAR_DIR="$DIRNAME/var"
[ -d "$HOME_DIR" ] || mkdir -p "$HOME_DIR"
[ -d "$SCAN_DIR" ] || mkdir -p "$SCAN_DIR"
[ -d "$FAILED_DIR" ] || mkdir -p "$FAILED_DIR"
[ -d "$TMP_DIR" ] || mkdir -p "$TMP_DIR"
[ -d "$VAR_DIR" ] || mkdir -p "$VAR_DIR"


PID="$VAR_DIR/$BASENAME.pid"
LOG="$VAR_DIR/${BASENAME}.log"

CPDF_TOOL="$DIRNAME/cpdf"
RIDGE="$VAR_DIR/Ridge-large.pdf"
DPI=300
#DEBUG=0
# SCAN_INTERVAL in seconds
SCAN_INTERVAL=60 
MAIL_FROM='korolev-ia@yandex.ru'
MAIL_TO='korolev-ia@yandex.ru'


w2log() {
	DATE=`date +%Y-%m-%d_%H:%M:%S`
	if [ "x$DEBUG" == "x1" ]; then
		echo "$DATE $1"
	fi
		echo "$DATE $1" >> $LOG
	return 0
}

get_size() {
	WIDTH=`identify $1 | awk '{print $3}' | sed 's/x[0-9][0-9]*$//'`
	HEIGHT=`identify $1 | awk '{print $3}' | sed 's/^[0-9][0-9]*x//'`
	return 0
}


send_mail() {
	# usage : send_mail 'subject' 'mail body'
	if [ "x$DEBUG" == "x1" ]; then
		echo "######## MAIL SUBJECT:" $1
		echo "######## MAIL BODY:" $2
	else
		# for ubuntu
		echo "'$2'" | mailx -r "'$MAIL_FROM'" -s "'$1'" -t "'$MAIL_TO'"
		return $?
		# for debian
		#echo "'$2'" | mailx  -a "From:$MAIL_FROM" -s "'$1'" "'$MAIL_TO'"
	fi	
	return 0
}

remove_temporary_files() {
	rm $PDF_PAGE_FIRST $PDF_PAGE_LAST $IMG_PAGE_FIRST $IMG_PAGE_LAST $RIDGE_RESIZED &1>/dev/null 2>&1
	return $?
}

init_temporary_filenames() {
		sleep 1
		DT=`date +%s`
		#DT=`date +%Y-%m-%d_%H:%M:%S`
		PDF_BASENAME=`basename $1`
		#PDF_OUTPUT="${HOME_DIR}/${PDF_BASENAME}_${DT}_RECOMPOSITE.pdf"
		PDF_RECOMPOSITE="${HOME_DIR}/${PDF_BASENAME}_${DT}_RECOMPOSITE.pdf"
		PDF_WITHOUT_FIRST_AND_LAST_PAGES="${HOME_DIR}/${PDF_BASENAME}_${DT}_WITHOUT_FIRST_AND_LAST_PAGES.pdf"
		PDF_PAGE_FIRST="${TMP_DIR}/${DT}_FIRST.pdf"
		PDF_PAGE_LAST="${TMP_DIR}/${DT}_LAST.pdf"
		IMG_PAGE_FIRST="${TMP_DIR}/${DT}_FIRST.png"
		IMG_PAGE_LAST="${TMP_DIR}/${DT}_LAST.png"
		RIDGE_RESIZED="${TMP_DIR}/${DT}_RIDGE.png"
		return 0
}

looking_for_new_files() {
	for i in `ls -1 $SCAN_DIR/*.pdf 2>/dev/null`; do	
		init_temporary_filenames "$i"
		# check if file fileshed upload
		SIZE_0=`/usr/bin/stat -c %s $i`
		sleep 10
		SIZE_1=`/usr/bin/stat -c %s $i`
		if [ $SIZE_0 == $SIZE_1 ]; then
			# we will move file from SCAN to VAR dir
			mv $i $VAR_DIR
			if [ $? -ne 0 ]; then
				w2log "Cannot move files '$i' to '$VAR_DIR'"
				send_mail "PDF file processed. Error" "Cannot move file '$i' to '$VAR_DIR'. May take many times processing. Please check permission for '$i', '$VAR_DIR'"
				continue
			fi
			PDF_BASENAME=`basename ${i}`
			PDF_ORIGINAL="$VAR_DIR/$PDF_BASENAME"
			
			recomposite_file $PDF_ORIGINAL
			if [ $? -ne 0 ]; then
				remove_temporary_files			
				rm $PDF_RECOMPOSITE $PDF_WITHOUT_FIRST_AND_LAST_PAGES
				w2log "Failed. Processing of file '$PDF_ORIGINAL': unsuccess"
				mv $PDF_ORIGINAL $FAILED_DIR ||  w2log "Cannot move file '$PDF_ORIGINAL' to '$FAILED_DIR'"
				send_mail "PDF file processing failed" "Failed Processing of file '$PDF_ORIGINAL': unsuccess. See log $LOG"
			else
				remove_temporary_files			
				w2log "Processing of file '$PDF_ORIGINAL': success"
				ZIP_FILE="${HOME_DIR}/${PDF_BASENAME}_RESULT.zip"
				/usr/bin/zip -m -j $ZIP_FILE $PDF_WITHOUT_FIRST_AND_LAST_PAGES $PDF_RECOMPOSITE
					if [ $? -ne 0 ]; then
						w2log "Cannot zip files '$PDF_WITHOUT_FIRST_AND_LAST_PAGES', '$PDF_RECOMPOSITE' to '$ZIP_FILE'"
						send_mail "PDF file processed. Warning" "Processing of file '$PDF_ORIGINAL': success. But Cannot zip files '$PDF_WITHOUT_FIRST_AND_LAST_PAGES', '$PDF_RECOMPOSITE' to '$ZIP_FILE'"
					fi
					# it may be serios error if we cannot move file from SCAN_DIR
				send_mail "PDF file processed" "Processing of file '$PDF_ORIGINAL': success. All ok. Zip file saved to '$ZIP_FILE'"
			fi
		else
			continue
		fi
	done
	return 0
}


recomposite_file() {
PDF_FILE=$1	

		if [ ! -r $RIDGE ]; then
			w2log	"File '$RIDGE' do not exist"
			return 1
		fi
	
PAGE_COUNT=`$CPDF_TOOL -info $PDF_FILE  | grep ^Pages: | sed 's/^Pages: *//'`	
		if [ "x$PAGE_COUNT" == "x" ]; then
			w2log	"Cannot count the pages in file '$PDF_FILE'"
			return 1
		fi

		if [ "$PAGE_COUNT" -lt "3" ]; then
			w2log	"There is less than 3 pages in '$PDF_FILE'. Cannot processing this file."
			return 1
		fi
		
$CPDF_TOOL $PDF_FILE 1 -o $PDF_PAGE_FIRST
		if [ $? -ne 0 ]; then
			w2log	"Cannot cut first page from file '$PDF_FILE'"
			return 1
		fi
		
$CPDF_TOOL $PDF_FILE end -o $PDF_PAGE_LAST
		if [ $? -ne 0 ]; then
			w2log	"Cannot cut last page from file '$PDF_FILE'"
			return 1
		fi
	
$CPDF_TOOL $PDF_FILE 2-~2 -o $PDF_WITHOUT_FIRST_AND_LAST_PAGES
		if [ $? -ne 0 ]; then
			w2log	"Cannot make new file without first and last pages from '$PDF_FILE'"
			return 1
		fi		
		
		
convert -units PixelsPerInch -density $DPI $PDF_PAGE_FIRST -units PixelsPerInch -density $DPI $IMG_PAGE_FIRST
		if [ $? -ne 0 ]; then
			w2log	"Cannot convert file '$PDF_PAGE_FIRST' to '$IMG_PAGE_FIRST'"
			return 1
		fi
convert -units PixelsPerInch -density $DPI $PDF_PAGE_LAST  -units PixelsPerInch -density $DPI $IMG_PAGE_LAST
		if [ $? -ne 0 ]; then
			w2log	"Cannot convert file '$PDF_PAGE_LAST' to '$IMG_PAGE_LAST'"
			return 1
		fi

get_size $IMG_PAGE_FIRST
HEIGHT_FIRST=$HEIGHT
WIDTH_FIRST=$WIDTH

get_size $IMG_PAGE_LAST
HEIGHT_LAST=$HEIGHT
WIDTH_LAST=$WIDTH

if [ -z $HEIGHT_FIRST ]; then
			w2log	"Get incorrect heigth of '$IMG_PAGE_FIRST'"
			return 1
fi
if [ $HEIGHT_FIRST != $HEIGHT_LAST ]; then
			w2log	"Heigth of '$IMG_PAGE_FIRST' is not the same for '$IMG_PAGE_LAST'"
			return 1
fi

# set the width of ridge to 0.15( mm )*page_count
let RIDGE_WIDTH=" $PAGE_COUNT * 1772 / 1000 "
# summary width of output pdf
let OUTPUT_WIDTH=" $WIDTH_FIRST + $RIDGE_WIDTH + $WIDTH_LAST "
# ident for last_image
let IDENT=" $RIDGE_WIDTH + $WIDTH_LAST "


convert $RIDGE -resize ${RIDGE_WIDTH}x${HEIGHT_FIRST}! $RIDGE_RESIZED
		if [ $? -ne 0 ]; then
			w2log	"Cannot resize image '$RIDGE' to size ${RIDGE_WIDTH}x${HEIGHT_FIRST} and save to '$RIDGE_RESIZED'"
			return 1
		fi
convert -size ${OUTPUT_WIDTH}x${HEIGHT_FIRST} xc:white $IMG_PAGE_LAST -geometry +0+0 \
	-composite $RIDGE_RESIZED  -geometry +${WIDTH_FIRST}+0 \
	-composite $IMG_PAGE_FIRST -geometry +${IDENT}+0 -units PixelsPerInch -density $DPI \
	-composite $PDF_RECOMPOSITE
		if [ $? -ne 0 ]; then
			w2log	"Cannot composite images '$IMG_PAGE_FIRST','$RIDGE_RESIZED','$IMG_PAGE_LAST' to '$PDF_RECOMPOSITE'"
			return 1
		fi
# all ok
return 0
}
		

if [ -f $PID ]; then
	ps --pid `cat $PID` -o cmd h | grep $BASENAME >/dev/null 2>&1 
	if [ $? -eq 0 ]; then
		w2log "Another process $BASENAME running. Exiting"
		exit 0
		#kill -9 `cat $PID` >/dev/null 2>&1
		#rm $PID
	fi				
fi
echo $$ > $PID

# main loop

while [ 1 ]; do
	looking_for_new_files
	sleep $SCAN_INTERVAL
done

		
		
	
