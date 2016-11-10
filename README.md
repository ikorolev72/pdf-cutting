#						pdf recombine pages


##  What is it?
##  -----------
Script for recombine pages in pdf file.  
Extract the 1st and the Last page of the PDF file and remove them from the original PDF file.
After the 1st and the Last page were extracted, then they should be adjoined together on a 
large single page PDF file and include an external image(or pdf file) inserted between them. 
The both pdf files zipped and saved in the home folder.


### How to install
	1. sudo apt-get install -y poppler-utils imagemagick mailutils zip
	2. Put file `recombine_pdf.sh` in your preffered directory.
	3. Set in file `recombine_pdf.sh` variables: `HOME_DIR, SCAN_DIR, RIDGE, MAIL_FROM, MAIL_TO, SCAN_INTERVAL` to your values
	4. Put file Ridge-large.pdf to path you defined in variable RIDGE
		
	
### How to run
There three ways to run:
   1. From command line. Usualy for testing resone. Simple run ```./recombine_pdf.sh```
   2. From crontab. Add next line to your crontab with ```crontab -e``` command:
   ```
*	*	*	*	*	/YOUR_PATH/recombine_pdf.sh >/dev/null 2>&1
   ```
   3. From command line as daemon. Run ```nohup /YOUR_PATH/recombine_pdf.sh &```
      
	  
	  
  Licensing
  ---------
	GNU

  Contacts
  --------

     o korolev-ia [at] yandex.ru
     o http://www.unixpin.com

