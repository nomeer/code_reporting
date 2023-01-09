#!/bin/bash
current_year=$(date +%Y)  # Get the current year
current_monthday=$(date +%m%d)  # Get the current month and day as a numeric string
table=log_$current_year
if [ "$current_monthday" -eq "0101" ]; then
  # Current date is January 1st
  table=log_$((current_year - 1))
fi

echo "The value of the table variable is $table"

dates=$(date --date="1 days ago" +"%Y-%m-%d")
recipients='nomeersh@gmail.com'
MYSQL_USER=root
MYSQL_PASSWORD=password
MYSQL_DATABASE=db

PACKAGE_IDS=(176 177 178 179 180 181 182 183 184 185 186)

# Define an array of package names and corresponding emails subjects
declare -A PACKAGE_EMAILS=(
  [176]="Boosting Mini voice Offer subscription attempts by customers"
  [177]="Boosting Small voice Offer subscription attempts by customers"
  [178]="Boosting Micro voice Offer subscription attempts by customers"
  [179]="Boosting Macro Voice Bundle subscription attempts by customers"
  [180]="Boosting Mega Voice Bundle subscription attempts by customers"
  [181]="Boosting Mini Data Offer subscription attempts by customers"
  [182]="Boosting Small Data Offer subscription attempts by customers"
  [183]="Boosting Micro Data Bundle subscription attempts by customers"
  [184]="Boosting Macro Data Bundle subscription attempts by customers"
  [185]="Boosting Big Data Bundle subscription attempts by customers"
  [186]="Boosting Mega Data Bundle subscription attempts by customers"

)
echo $PACKAGE_EMAILS 
# Loop through the array of package IDs
for package_id in "${PACKAGE_IDS[@]}"; do
  # Execute the MySQL query and save the results to a CSV file
  echo $PACKAGE_IDS
  mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "
    SELECT 'MSISDN','Sub/Unsub','SIM PACKAGE','status','Status_Info','result','Date and Time','Subscription channel'
    UNION ALL
    SELECT msisdn,action,package,status,result,note,modified_on,
           IF(modified_by= '9', 'SMS', IF(modified_by='11','USSD',IF(modified_by='10', 'IVR', 'Agent')))
    FROM $table
    WHERE package = $package_id AND date(modified_on) = '$dates'
    INTO OUTFILE '/cvm_data/bsco/reports/report_${package_id}_$dates.csv'
    FIELDS TERMINATED BY ',' LINES TERMINATED BY '\n';"

  # Send an email with the CSV file attached
  /home/bsco/venv/bin/python /root/scripts/send_email.py \
    -b "Please find attached the report for ${PACKAGE_EMAILS[$package_id]}" \
    -s "${PACKAGE_EMAILS[$package_id]} Daily Report" \
    -a "/cvm_data/bsco/reports/report_${package_id}_$dates.csv" \
    -r "$recipients"
done


edit /root/scripts/send_email.py


#!/usr/bin/env python
# test smtp auth
# -*- coding: utf-8 -*-

import os
from datetime import datetime, timedelta
import smtplib
import base64
import socket
from dotenv import load_dotenv
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email.mime.text import MIMEText
from email.encoders import encode_base64
import argparse
from datetime import datetime, timedelta

load_dotenv('/root/scripts/.env.email')  # take environment variables from .env.


SENDER = os.getenv("SENDER")
PASS = os.getenv("PASS")
SERVER = os.getenv('SERVER')
PORT = os.getenv('PORT')

def email_attach(subject, body, files, recipients):

    
    msg = MIMEMultipart()
    msg['Subject'] = f'{subject} - {socket.gethostname()}' 
    msg['From'] = SENDER
    msg['To'] = ','.join(recipients)

    body = MIMEText(body) # convert the body to a MIME compatible string
    msg.attach(body)

    for f in files:
        if not os.path.exists(f):
            print(f + ' not exists')
            return

        part = MIMEBase('application', "octet-stream")
        part.set_payload(open(f, "rb").read())
        encode_base64(part)    
        part.add_header('Content-Disposition', f'attachment; filename="{os.path.basename(f)}"')

        msg.attach(part)
    
    server = smtplib.SMTP(SERVER, PORT)
    server.set_debuglevel(2)
    server.ehlo()
    server.starttls()
    server.ehlo()
    server.login(SENDER, PASS)
    server.sendmail(SENDER, recipients, msg.as_bytes())
    server.quit()

if __name__=="__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-s' ,'--subject', help='the subject of the email', type=str, required=True)
    parser.add_argument('-b', '--body', help='the body of the email', type=str, required=True)
    parser.add_argument('-a', '--attachment', help='file path to attach', type=str, required=True)
    parser.add_argument('-r', '--recipients', help='comma separated list of recipients', type=str, required=True)

    args = parser.parse_args()
    #print(args.subject) 
    #print(args.body) 
    #print(args.attachment) 
    #print(args.recipients.split(',')) 
    email_attach(args.subject, args.body, args.attachment.split(','), args.recipients.split(','))

edit  /root/scripts/.env.email


# used by send_emails.py
SENDER=email
PASS=password
SERVER=outlook.*.com
PORT=587
