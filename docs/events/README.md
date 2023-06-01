Задачи:
* [[kubernetes] Требование к типам регистрируемых событий](https://my.basealt.space/issues/93266)
* [[podman] Требование к типам регистрируемых событий](https://my.basealt.space/issues/93258)

* [Auditing](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)

* [kube-apiserver Audit Configuration (v1)](https://kubernetes.io/docs/reference/config-api/apiserver-audit.v1/)

* [Kubernetes Audit Logs - Best Practices And Configuration](https://signoz.io/blog/kubernetes-audit-logs/)


> Регистрации подлежат как минимум следующие события безопасности:
> 
>     * неуспешные попытки аутентификации пользователей средства контейнеризации;

```
 jq '. | select(.responseStatus.code == 403 and (.user.groups | contains(["system:unauthenticated"])))'
```
<pre>
{
  "kind": "Event",
  "apiVersion": "audit.k8s.io/v1",
  "level": "Metadata",
  "auditID": "a2a4029d-5d49-4321-8c64-47847d3bd7a5",
  "stage": "ResponseComplete",
  "requestURI": "/",
  "verb": "get",
  "user": {
    "username": "system:anonymous",
    "groups": [
      "system:unauthenticated"
    ]
  },
  "sourceIPs": [
    "192.168.122.1"
  ],
  "userAgent": "curl/7.88.1",
  "responseStatus": {
    "metadata": {},
    "status": "Failure",
    "message": "forbidden: User \"system:anonymous\" cannot get path \"/\"",
    "reason": "Forbidden",
    "details": {},
    "code": 403
  },
  "requestReceivedTimestamp": "2023-03-11T14:37:29.839911Z",
  "stageTimestamp": "2023-03-11T14:37:29.851870Z",
  "annotations": {
    "authorization.k8s.io/decision": "forbid",
    "authorization.k8s.io/reason": ""
  }
}

</pre>

>     * создание, модификация и удаление образов контейнеров;
>     * получение доступа к образам контейнеров;
>     * запуск и остановка контейнеров с указанием причины остановки;
```
get events -A | grep -y 'container
> image'
```
<pre>
default       51m         Normal    Killing             pod/nginx-deployment-6595874d85-4l2s7    Stopping container nginx
default       51m         Normal    Killing             pod/nginx-deployment-6595874d85-5kj76    Stopping container nginx
default       51m         Normal    Pulled              pod/nginx-deployment-6595874d85-c2tnf    Container image "nginx:1.14.2" already present on machine
default       51m         Normal    Created             pod/nginx-deployment-6595874d85-c2tnf    Created container nginx
default       51m         Normal    Started             pod/nginx-deployment-6595874d85-c2tnf    Started container nginx
default       51m         Normal    Pulled              pod/nginx-deployment-6595874d85-j7z2d    Container image "nginx:1.14.2" already present on machine
default       51m         Normal    Created             pod/nginx-deployment-6595874d85-j7z2d    Created container nginx
default       51m         Normal    Started             pod/nginx-deployment-6595874d85-j7z2d    Started container nginx
kube-system   7m57s       Normal    Pulled              pod/coredns-79cdf897dd-9c82g             Container image "registry.local/k8s-p10/coredns:v1.8.6" already present on
</pre>
Выявляем имена контейнеров, pod'ов, образов

Факты и авторов создания выявляем по запросы к аудиту API:
```
jq '. | select(.verb=="create" and .objectRef.resource=="pods")'
jq '. | select(.verb=="create" and .objectRef.resource=="deployments")'
...

```


>     * изменение ролевой модели;

* запрос на подпись сертификата:
```
 jq '. | select(.objectRef.resource=="certificatesigningrequests" and .verb=="create")'
```

* подпись сертификата
```
jq '. | select(.objectRef.resource=="certificatesigningrequests" and .verb=="update")'
```

* запросы пользователя
```
jq '. | select(.user.username=="user1" )'
```

* создание кластерной роли
```
select(.objectRef.resource=="clusterroles" and .verb=="create")'
```

* связывание кластерной роли
```
jq '. | select(.objectRef.resource=="clusterrolebindings" and .verb=="create")'
```


* связывание обычной роли
```
jq '. | select(.objectRef.resource=="rolebindings" and .verb=="create")'
```

>     * модификация запускаемых контейнеров
Выявление фактов удаленного запуска команд в контейнере:
```
jq '. | select(.objectRef.subresource=="exec")'
```

>     * выявление известных уязвимостей в образах контейнеров и некорректности конфигурации;
>     * факты нарушения целостности объектов контроля.
> 
> Для каждого события безопасности должны регистрироваться:
> 
>     * описание события безопасности;
>     * сведения о критичности события безопасности.
> 
> В журнал событий безопасности информационной (автоматизированной) системы должна обеспечиваться запись событий > > > > > безопасности контейнеров с указанием идентификатора пользователя хостовой ОС, от имени которого был запущен контейнер.


Ссылки:
* [A Practical Guide to Kubernetes Logging](https://logz.io/blog/a-practical-guide-to-kubernetes-logging/)
* [Logging Architecture](https://kubernetes.io/docs/concepts/cluster-administration/logging/)
* [Securing Kubernetes with Open Source Falco and Logz.io Cloud SIEM](https://logz.io/blog/k8s-security-with-falco-and-cloud-siem/)
