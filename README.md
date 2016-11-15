#						pdf recombine pages


##  What is it?
##  -----------
Script for recombine pages in pdf file.  
Extract the 1st and the Last page of the PDF file and remove them from the original PDF file.
After the 1st and the Last page were extracted, then they should be adjoined together on a 
large single page PDF file and include an external image(or pdf file) inserted between them. 
The both pdf files zipped and saved in the home folder.


##  The Latest Version

	version 1.2 2016.11.15
	
##  Whats new
	+ Using `cpdf` instead `pdfinfo, pdfseparate`
	+ Change last and first pages in result file
	+ Produce one more file without first and last pages
	+ Remove directories paths in zip file


### How to install
	1. extract the archive with command `tar xf recombine_pdf.tgz` in preffered directory
	2. `sudo apt-get install -y imagemagick mailutils zip`
	3. `cd recombine_pdf` . Set in file `recombine_pdf.sh` variables: `HOME_DIR, SCAN_DIR, RIDGE, MAIL_FROM, MAIL_TO, SCAN_INTERVAL` to your values ( eg `HOME_DIR=/home/svodka` )
	4. If you change the value of RIDGE, then put the file `Ridge-large.pdf` to path you defined in variable `RIDGE`
		
	
### How to run
   Run from command line as daemon. Run ```nohup /YOUR_PATH/recombine_pdf.sh &```
      
	  
	  
  Licensing
  ---------
	GNU

  Contacts
  --------

     o korolev-ia [at] yandex.ru
     o http://www.unixpin.com

