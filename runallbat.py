import glob
import os
import sys
import smtplib
import string
import subprocess


fromStr = "coa-gis-fme1@ashevillenc.gov"
textStr = "Failed to run "
stmpIP = "192.168.0.102"
subjectStr = "GIS Wharehouse update failure"

#get command deliminated email list
args =  sys.argv
emailsargs = args[2].split(",")

you = emailsargs

toStr = you

for fn in glob.glob(args[1] +"*.bat"):
    try:
        #os.startfile(fn)
        p = subprocess.Popen([fn]); 
        if p.wait() <> 0:
            SUBJECT = subjectStr
            TO = ",".join(toStr)
            FROM = fromStr
            text = textStr + fn
            BODY = string.join((
                    "From: %s" % FROM,
                    "To: %s" % TO,
                    "Subject: %s" % SUBJECT ,
                    "",
                    text
                    ), "\r\n")
            server = smtplib.SMTP(stmpIP)
            server.sendmail(FROM, you , BODY)
            server.quit()
            print "Data export failed for: " + fn
        else:
            print "Data export succeded for: " + fn
    except:
            SUBJECT = subjectStr
            TO = ",".join(toStr)
            FROM = fromStr
            text = textStr + fn
            BODY = string.join((
                    "From: %s" % FROM,
                    "To: %s" % TO,
                    "Subject: %s" % SUBJECT ,
                    "",
                    text
                    ), "\r\n")
            server = smtplib.SMTP(stmpIP)
            server.sendmail(FROM, you, BODY)
            server.quit()
            print "Data export failed for: " + fn
