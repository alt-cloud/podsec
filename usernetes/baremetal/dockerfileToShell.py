#!/usr/bin/python3
import json, sys
import shlex
from pprint import pprint
from dockerfile_parse import DockerfileParser

#out = open('../usernetes/createUsernetes.sh', 'w')
#sys.stdout = out
print ('#!/bin/sh')
dfp = DockerfileParser("../usernetes/Dockerfile")
djson = json.loads(dfp.json)
for instr in  djson:
  for key in instr:
    if key == 'FROM' or key == 'COMMENT' or key == 'VOLUME' or key == 'HEALTHCHECK' or key == 'ENTRYPOINT':
      continue
    value = instr[key]
    # print("key=", key)
    # print("value=", value)
    if key == "RUN":
      if value[0:14]:
        value = value.replace('openssh','')
      print("sh -c " + shlex.quote(value))
    if  key == 'COPY' or key=='ADD' :
      if value[0:8] == '--chown=':
        cmd = value.split(' ')
        value =' '.join(cmd[1:])
        print("cp -R ", value)
        print ("chown -R " + cmd[0][8:] + ' ' + cmd[2])
      else:
        print("cp ", value)

    # print ("key: %s , value: %s" % (key, djson[key]))
    # print(key, djson[key])
  # print (instr)

