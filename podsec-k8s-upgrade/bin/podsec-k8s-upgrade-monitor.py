#!/usr/bin/python3

class Node:

  def __init__(self):
    pass

  def update(self):
    cmd = "kubectl  get all -A -o json"
    fp = os.popen(cmd)
    reply = fp.read()
    self.state = json.loads(reply)
    fp.close()

class Nodes :
  currentState = None
  oldState = None

  def __init__(self):
    pass

  def update(self):
    self.oldState = self,newState
    self.newState = new Node()



def nodeStatus(nodeName):
  cmd = """
    kubectl  get all -A -o json |
    jq  '
      .items[] |
      select(.metadata.generateName=="kube-proxy-") |
      select(.spec.nodeName=="%s") |
      .status.containerStatuses[-1].state'
  """ % nodeName
  fp = os.popen(cmd)
  reply = fp.read()
  # print('REPLY=', reply)
  fp.close()
  ret = json.loads(reply)
  return ret


def listCordonedNodes():
  cmd = """
kubectl  get nodes -o json |
    jq  '
      [.items[] |
      if .spec.unschedulable!=null
      then .metadata.name
      else empty
      end]'
  """
  fp = os.popen(cmd)
  reply = fp.read()
  fp.close()
  ret = json.loads(reply)
  return ret

def clear():
  os.system('clear >&2')

def imageInfo(image):
  registryPath = os.path.dirname(image)
  imageTag = os.path.basename(image).split(':')
  if len(imageTag) < 2:
    return {'registryPath': '', 'image': '', 'tag': ''}
  image = imageTag[0]
  tag = imageTag[1].strip()
  if len(tag) > 0 and tag[0] == 'v':
    tag = tag[1:]
  return {'registryPath': registryPath, 'image': image, 'tag': tag}

def getKubePodImageTag(node, podName):
  cmd = """
    kubectl get -n kube-system pod/%s-%s -o json 2>/dev/null |
    jq -r '.spec.containers[0].image'
    """ % (podName, node)
  fp = os.popen(cmd)
  image = fp.read()
  # print('Node=%s Reply=%s' % (node, reply))
  fp.close()
  return imageInfo(image)

def getDaeminsetImageTag(node, generateName):
  cmd = """
    kubectl  get all -A -o json |
    jq -r '
      .items[] |
      select(.metadata.generateName=="%s") |
      if .spec.nodeName=="%s" then .spec.containers[0].image
      else empty
      end'
    """ % (generateName ,node)
  fp = os.popen(cmd)
  image = fp.read()
  # print('Node=%s Reply=%s' % (node, reply))
  fp.close()
  return imageInfo(image)

def getKubeletVersion(node):
  cmd = 'ssh %s kubelet --version' % node
  fp = os.popen(cmd)
  version = fp.read()
  fp.close()
  words=version.split(' ')
  version = words[1][1:-1]
  return version

def getNodesStates(nodes):
  ret = {}
  cordonNodes = listCordonedNodes()
  for node in nodes:
    ret[node] = {}
    ret[node]['kubelet'] = getKubeletVersion(node)
    for daemonPod in daemonPods:
      ret[node][daemonPod] = getDaeminsetImageTag(node, daemonPod+"-")
    for kubePod in kubePods:
      ret[node][kubePod] = getKubePodImageTag(node, kubePod)
    ret[node]['cordon'] = node in cordonNodes
    ret[node]['status'] = nodeStatus(node)
  # print('nodesStates=', json.dumps(ret, indent=2))
  sys.stdout.flush()
  return ret

def statesCompare(nodesStates, oldNodeStates):
  ret = []
  for nodeName in nodesStates:
    nodeState = nodesStates[nodeName]
    if nodeName not in oldNodeStates:
      ret.append('Узел %s не обнаружен в стеке' % (nodeName))
    else:
      oldNodeState = oldNodeStates[nodeName]
      if 'cordon' not in nodeState or 'cordon' not in oldNodeState:
        ret.append('Узел %s неготов' % nodeName)
        continue
      if nodeState['cordon'] != oldNodeState['cordon']:
        if nodeState['cordon']:
          oldCordonStatus = 'uncordon'
          newCordonStatus = 'cordon'
        else:
          oldCordonStatus = 'cordon'
          newCordonStatus = 'uncordon'
        ret.append('Статус узла %s изменился с %s на %s' %(nodeName, oldCordonStatus, newCordonStatus))
      for daemonPod in daemonPods:
        if nodeState[daemonPod]['tag'] != oldNodeState[daemonPod]['tag']:
          ret.append('Версия pod`а ' + daemonPod + ' узла %s изменился с %s на %s' %(nodeName, oldNodeState[daemonPod]['tag'], nodeState[daemonPod]['tag']))
      for kubePod in kubePods:
        if nodeState[kubePod]['tag'] != oldNodeState[kubePod]['tag']:
          ret.append('Версия pod`а ' + kubePod + ' узла %s изменился с %s на %s' %(nodeName, oldNodeState[daemonPod]['tag'], nodeState[kubePod]['tag']))
      newStatus = ''.join(nodeState['status'].keys())
      oldStatus = ''.join(oldNodeState['status'].keys())
      if newStatus != oldStatus:
        ret.append('Состояние узла %s изменился с %s на %s' %(nodeName, oldStatus, newStatus))
  ret = ''.join(ret)
  # print('statesCompare:: ret=%s' % ret)
  sys.stdout.flush()
  return ret

#MAIN
import os, sys, json, time, datetime
daemonPods = ['kube-proxy', 'kube-flannel-ds']
kubePods = ['etcd', 'kube-apiserver', 'kube-scheduler', 'kube-controller-manager']

fp = os.popen("kubectl get nodes -o json | jq  '[.items[].metadata.name]  | sort'")
nodes = json.loads(fp.read())
fp.close()

nodesStates = getNodesStates(nodes)

print('nodesStates=', json.dumps(nodesStates, indent=2))
sys.exit(0)

first = True
oldNodeStates = nodesStates
while True:
  compareStr = statesCompare(nodesStates, oldNodeStates)
  if not first and len(compareStr) == 0:
    first = False
    # print('Continue')
    sys.stdout.flush()
  else:
    first = False
    clear()
    str = compareStr + '\n'
    str += f"{datetime.datetime.now():%Y-%m-%d %H:%M:%S}" + '\n'
    str += 'Node '
    for daemonPod in daemonPods:
      str += '%s ' % daemonPod
    for kubePod in kubePods:
      str += '%s ' % kubePod
    str += 'state cordon time\n'
    str += "-----------------------------------------------\n"
    for nodeName in nodesStates:
      nodeState = nodesStates[nodeName]
      if 'status' not in nodeState:
        str += nodeName + '\n'
        continue
      str += '%s ' %  nodeName
      for daemonPod in daemonPods:
        tag = nodeState[daemonPod]['tag']
        if tag[0] == 'v':
          tag = tag[1:]
        str += "%s " % tag
      for kubePod in kubePods:
        tag = nodeState[kubePod]['tag']
        # if tag[0] == 'v':
        #   tag = tag[1:]
        str += "%s " % tag
      status = ''.join(nodeState['status'].keys())
      cordon = 'cordon' if nodeState['cordon'] else 'uncordon'
      str += "%s %s " % (status,cordon)
      if status == 'running':
        Status = nodeState['status']['running']['startedAt']
      elif status == 'waiting':
        Status = nodeState['status']['waiting']['reason'] + ' ' + nodeState['status']['waiting']['message']
      str += '%s ' % Status
      str += '\n'
    str += "-----------------------------------------------\n"
    print(str, file=sys.stderr)
    sys.stderr.flush()
    print(str)
    sys.stdout.flush()
  time.sleep(1)
  oldNodeStates = dict(nodesStates)
  nodesStates = getNodesStates(nodes)


