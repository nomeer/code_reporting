#modules declaring
import logging,pymysql,datetime
from datetime import date, timedelta
from dateutil.relativedelta import relativedelta
import datetime
#logger custom
logging.basicConfig(format='%(asctime)s - %(message)s', level=logging.DEBUG)


db = pymysql.connect(host='ip',
                         user='nomeer',
                         password='pass',
                         database='db',
                         cursorclass=pymysql.cursors.DictCursor,
                         autocommit=False)
cursor = db.cursor()
#all dates
#yesterday date
ed = date.today() - timedelta(1)
#today date
todayDate = datetime.date.today()
#year 2023
year=todayDate.year
#month Januray 01
month=todayDate.strftime("%B%d")
#last year
year_ago =datetime.date.today() - relativedelta(years=1)
#last year with defined 2022
last_year =year_ago.strftime("%Y") 
#two year ago 2021
two_year_ago =datetime.date.today() - relativedelta(years=2)
#two last year with defined 2021
two_last_year =two_year_ago.strftime("%Y")
#first day of the month
last_first_day=year_ago.replace(day=1)
#it will give the last date of the month
last_ed= year_ago - timedelta(1)
#same concept goes from below dates
month_ago=datetime.date.today() - relativedelta(months=1)
lm_first_day=month_ago.replace(day=1)
lm_ed=month_ago -timedelta(1)
first_day=todayDate.replace(day=1)
lastmonth=month_ago.month
currentmonth=todayDate.month
if first_day > ed:
#looks like its the end of the month, so lets fudge the date
   # lm_ed=month_ago - timedelta(1)
    first_day=ed.replace(day=1)
    last_first_day=last_ed.replace(day=1)
    lm_first_day=lm_ed.replace(day=1)

table = 'nomeer_rr'
logging.debug(('starting'))
for q in [f'DROP TABLE IF EXISTS {table}', f'CREATE TABLE {table} LIKE tmp_revenue ']:
    cursor.execute(q)
    logging.debug(q)
db.commit()
logging.debug(('created'))
#change the year of first query to last_year each year
year=year
if  month=='January01':
    year=last_year
q = f'INSERT INTO {table} (created_date, created_by, subscription) SELECT created_date, created_by, subscription FROM log_archive_{year} WHERE created_date between "{str(first_day)}" and "{str(ed)}" AND action="Subscribe" AND status="Success"'
cursor.execute(q)
db.commit()
logging.debug((f' first query MTD log_archive_{year}', q))
logging.debug(("inserted"))

#change the year of first query to last_year each year
year=last_year
if  month=='January01':    
    year=last_year
q=f'INSERT INTO {table} ( created_date, created_by, subscription) SELECT created_date, created_by, subscription FROM log_archive_{year} WHERE created_date between  "{str(lm_first_day)}" AND "{str(lm_ed)}" AND  action="Subscribe" AND status="Success"'
cursor.execute(q)
db.commit()
logging.debug((f' second query LMTD table log_archive_{year}', q))

year=last_year
if month=='January01':
    year=two_last_year

q=f'INSERT INTO {table} ( created_date, created_by, subscription) SELECT created_date, created_by, subscription FROM log_archive_{year} WHERE created_date between "{str(last_first_day)}" and "{str(last_ed)}"  AND action="Subscribe" AND status="Success"'
cursor.execute(q)
db.commit()
logging.debug((f'third query LYMTD table log_archive_{year}', q))

for q in [f'UPDATE {table} r, subscription s SET r.value=s.value_afn WHERE r.subscription=s.name', f'UPDATE {table} r, subscription s, subscription_category c SET r.category=c.name WHERE r.subscription=s.name AND s.subscription_category_id=c.id']:
    cursor.execute(q)
    logging.debug(('updated',q))
db.commit()
db.close()
