import mailbox
import sys

from cStringIO import StringIO
from email.generator import Generator

def print_payload(message):
  # if the message is multipart, its payload is a list of messages
  if message.is_multipart():
	for part in message.get_payload(): 
		print_payload(part)
  else:
	#print message.get_payload(decode=True)
	fp = StringIO()
	g = Generator(fp, mangle_from_=False, maxheaderlen=60)
	g.flatten(message)
	text = fp.getvalue()
	print text
    
mbox = mailbox.mbox(sys.argv[1])
for message in mbox:
  #print message['From'],"\t",message['To'],"\t",message['subject'],"\t",message['body']
  print_payload(message)
