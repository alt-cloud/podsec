podsec-inotify-check-kubeapi(1) -- скрипт мониторинга аудита API-интерфейса kube-apiserver control-plane узла
================================

## SYNOPSIS

`podsec-inotify-check-kubeapi [-d]`

## DESCRIPTION

Скрипт производит мониторинг файла `/etc/kubernetes/audit/audit.log` аудита API-интерфейса `kube-apiserver`.

Политика аудита располагается в файле `/etc/kubernetes/audit/policy.yaml`:
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

Текущие настройки производят логирование всех обращений "несистемных" пользователей (в том числе анонимных) к ресурсам `kubernetes`.

Скрипт производит выборку всех обращений, в ответ на которые был сформирован код более `400` - запрет доступа.
Все эти факты записываются в системный журнал и накапливаются в файле логов `/var/lib/podsec/u7s/log/kubeapi/forbidden.log`, который периодически передается через посту системному адмиристратору.

## OPTIONS

- `-d` - скирпт запускается в режиме демона, производящего онлайн мониторинг файла `/etc/kubernetes/audit/audit.log` и записывающего факты запросов с запретом доступа в системный журнал и файл логов `/var/lib/podsec/u7s/log/kubeapi/forbidden.log`.

- `-m` - скрипт посылает файл логов `/var/lib/podsec/u7s/log/kubeapi/forbidden.log` почтой системному администратору (пользователь `root`) и обнуляет файл логов.

В состав пакета кроме этого скрипта входят:

- файл описания сервиса `/lib/systemd/system/podsec-inotify-check-kubeapi.service`. Для его запуска необходимо выполнить команды:
  <pre>
  # systemctl enable  podsec-inotify-check-kubeapi.service
  # systemctl start  podsec-inotify-check-kubeapi.service
  </pre>

- Файла расписания `/lib/systemd/system/podsec-inotify-check-kubeapi-mail.timer`, задающий в параметре `OnCalendar` расписание запуска сервиса `/lib/systemd/system/podsec-inotify-check-kubeapi-mail.timer`. Таймер вызывается ежечасно.

По умолчанию таймер запуска сервиса выключен. Для его включения наберите команду:
<pre>
#  systemctl enable --now podsec-inotify-check-kubeapi-mail.timer
</pre>
Если необходимо изменить режим запуска скрипта отредактируйте параметр `OnCalendar` файла расписания `podsec-inotify-check-kubeapi-mail.timer`.


## EXAMPLE

`podsec-inotify-check-kubeapi -d`

`podsec-inotify-check-kubeapi -m`


## SECURITY CONSIDERATIONS

Кроме мониторинга фактов запрета доступа возможен мониторинг других фактов подозрительной активности.

## SEE ALSO

* [Auditing](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)

* [kube-apiserver Audit Configuration (v1)](https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/)

* [Kubernetes Audit Logs - Best Practices And Configuration](https://signoz.io/blog/kubernetes-audit-logs/)

* [How to monitor Kubernetes audit logs](https://www.datadoghq.com/blog/monitor-kubernetes-audit-logs/#monitor-api-authentication-issues)


## AUTHOR

Костарев Алексей, Базальт СПО
kaf@basealt.ru
