@echo off
Set task_name=TASK_NAME
Set path_of_XML=C:\debf3bcc80a24d6aa090f9c093ff1c68\task.xml
echo schtasks /create /tn %task_name% /xml %path_of_XML%
schtasks /create /tn %task_name% /xml %path_of_XML%