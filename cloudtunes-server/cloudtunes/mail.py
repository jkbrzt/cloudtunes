import smtplib

from cloudtunes.worker import celery
from cloudtunes.settings import EMAIL


@celery.task
def send_email(recipient, subject, body):
    headers = '\r\n'.join([
        'From: ' + EMAIL['SENDER'],
        'Subject: ' + subject,
        'To: ' + recipient,
        'MIME-Version: 1.0',
    ])
    session = smtplib.SMTP(EMAIL['SMTP_SERVER'], EMAIL['SMTP_PORT'])
    session.ehlo()
    session.starttls()
    session.login(EMAIL['SENDER'], EMAIL['PASSWORD'])
    session.sendmail(EMAIL['SENDER'], recipient, headers + '\r\n\r\n' + body)
    session.quit()
