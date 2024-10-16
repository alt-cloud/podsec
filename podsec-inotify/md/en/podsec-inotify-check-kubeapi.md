podsec-inotify-check-kubeapi(1) -- kube-apiserver control-plane API audit monitoring script
=================================

## SYNOPSIS

`podsec-inotify-check-kubeapi [-d]`

## DESCRIPTION

The script monitors the `/etc/kubernetes/audit/audit.log` file for auditing the `kube-apiserver` API.

The audit policy is located in the `/etc/kubernetes/audit/policy.yaml` file:
<pre>
apiVersion: audit.k8s.io/v1
kind: Policy
omitManagedFields: true
rules:
# do not log requests to the following
- level: None
  nonResourceURLs:
  - "/healthz*"
  - "/logs"
  - "/metrics"
  - "/swagger*"
  - "/version"
  - "/readyz"
  - "/livez"

- level: None
  users:
    - system:kube-scheduler
    - system:kube-proxy
    - system:apiserver
    - system:kube-controller-manager
    - system:serviceaccount:gatekeeper-system:gatekeeper-admin

- level: None
  userGroups:
    - system:nodes
    - system:serviceaccounts
    - system:masters

# limit level to Metadata so token is not included in the spec/status
- level: Metadata
  omitStages:
  - RequestReceived
  resources:
  - group: authentication.k8s.io
    resources:
    - tokenreviews

# extended audit of auth delegation
- level: RequestResponse
  omitStages:
  - RequestReceived
  resources:
  - group: authorization.k8s.io
    resources:
    - subjectaccessreviews

# log changes to pods at RequestResponse level
- level: RequestResponse
  omitStages:
  - RequestReceived
  resources:
  - group: "" # core API group; add third-party API services and your API services if needed
    resources: ["pods"]
    verbs: ["create", "patch", "update", "delete"]

# log everything else at Metadata level
- level: Metadata
  omitStages:
  - RequestReceived
</pre>

Current settings log all requests from "non-system" users (including anonymous ones) to `kubernetes` resources.

The script selects all requests that resulted in a code greater than `400` - access denied.
All these facts are recorded in the system log and accumulated in the log file `/var/lib/podsec/u7s/log/kubeapi/forbidden.log`, which is periodically transmitted via post to the system administrator.

## OPTIONS

- `-d` - the script runs in daemon mode, performing online monitoring of the file `/etc/kubernetes/audit/audit.log` and recording the facts of requests with access denied in the system log and the log file `/var/lib/podsec/u7s/log/kubeapi/forbidden.log`.

- `-m` - the script sends the log file `/var/lib/podsec/u7s/log/kubeapi/forbidden.log` by mail to the system administrator (user `root`) and resets the log file.

In addition to this script, the package includes:

- the service description file `/lib/systemd/system/podsec-inotify-check-kubeapi.service`. To start it, you need to run the commands:
<pre>
# systemctl enable podsec-inotify-check-kubeapi.service
# systemctl start podsec-inotify-check-kubeapi.service
</pre>

- The schedule file `/lib/systemd/system/podsec-inotify-check-kubeapi-mail.timer`, which specifies the start schedule for the service `/lib/systemd/system/podsec-inotify-check-kubeapi-mail.timer` in the `OnCalendar` parameter. The timer is called every hour.

By default, the service startup timer is disabled. To enable it, enter the command:
<pre>
# systemctl enable --now podsec-inotify-check-kubeapi-mail.timer
</pre>
If you need to change the script startup mode, edit the `OnCalendar` parameter of the `podsec-inotify-check-kubeapi-mail.timer` schedule file.

## EXAMPLE

`podsec-inotify-check-kubeapi -d`

`podsec-inotify-check-kubeapi -m`

## SECURITY CONSIDERATIONS

In addition to monitoring access denials, other suspicious activity can be monitored.

## SEE ALSO

* [Auditing](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)
* [kube-apiserver Audit Configuration (v1)](https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/)
* [Kubernetes Audit Logs - Best Practices And Configuration](https://signoz. io/blog/kubernetes-audit-logs/)
* [How to monitor Kubernetes audit logs](https://www.datadoghq.com/blog/monitor-kubernetes-audit-logs/#monitor-api-authentication-issues)

## AUTHOR

Alexey Kostarev, Basalt LLC
kaf@basealt.ru
