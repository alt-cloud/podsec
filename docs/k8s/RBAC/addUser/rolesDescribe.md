# Описание основных классов ролей кластера (Roles, ClusterRoles) и механизмов из связываения с субъектами

Все контейнеры в `kubernetes` запускаются в рамках `Pod`'ов, которые в свои очередь входят в такие ресурсы как `replicaSet`, `deployments`, `statefullSet` и т.д.
Все это ресурсы взаимодействуют в рамках одного проекта (`namespace`).
Кроме этого кластер включает ресурсы, которые определены все конкретного проекта (`namespace`) - узлы (`nodes`), сертификаты и т.п.
Права пользователя на работу с этими ресурсами определяются ролями, с которыми они (пользователи) связаны.
В связи  этом роли делятся на два класса:
* `Roles` - определяют права пользователя в рамках конкретного namespace, с которым связана роль;
* `ClusterRoles` - определяют права пользователя в рамках использования ресурсов всего кластера.

Роль администратора информационной (автоматизированной) системы является кластерной ролью.
Кластер `kubernetes` поставляется с набором заранее подготовленных ролей.  
Кластерные роли образауют иерархию.

![Иерархия кластерных ролей](clusterRoleTree.png)

Кластерная роль (`ClusterRole`) | Доступ |	Что может делать
-------------------|--------|--------------------
`view` | Полный доступ только на чтение ко всем namespace-ресурсам за исключением "чувствительных" | Просмотр основных  namespace-ресурсов
`edit` | Полный доступ ко всем namespace-ресурсам за исключением `Role`, `RoleBinding`, `LocalSubjectAccessReviews` | Все в namespace за исключением granting и checking доступ
`admin` | Полный доступ ко всем namespace-ресурсам | Все в namespace
`cluster-admin` | Полный доступ ко всем кластерным ресурсам | Все в кластере

## Кластерная роль `view`

Кластерная роль `view` позволяет просматривать namespace-ресурсы во всех `namespace`'ах.
Она имеет агрегационное правило:
```
aggregationRule:
  clusterRoleSelectors:
    - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-view: "true"
metadata:
  name: view  
rules:
  ...
```
которое позволяет включать в эту роль роли, имеющие в метках значение 
```
rbac.authorization.k8s.io/aggregate-to-view: "true"
```
В предопределенных в `kubernetes` ролях эту метку имеет роль `system:aggregate-to-view`:
```
metadata:
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
  name: system:aggregate-to-view
rules:
  ...
```
Правила данной роли объединяются с правилами роли `view`.

Данный механизм позволяет администратору, обладающему праву работать с ролями расширять правила роли `view`, добавляя новые роли содержащие метку `rbac.authorization.k8s.io/aggregate-to-view: "true"`.

## Кластерная роль edit

Кластерная роль `edit` позволяет получить полный доступ ко всем namespace-ресурсам за исключением `Role`, `RoleBinding`, `LocalSubjectAccessReviews` во всех `namespace`'ах.
Она имеет аггрегационное правило:
```
aggregationRule:
  clusterRoleSelectors:
    - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-edit: "true"
metadata:
  name: edit  
rules:
  ...
```
которое позволяет включать в эту роль роли, имеющие в метках значение 
```
rbac.authorization.k8s.io/aggregate-to-edit: "true"
```
В предопределенных в `kubernetes` ролях эту метку имеет роль `system:aggregate-to-edit`:
```
metadata:
  labels:
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
  name: system:aggregate-to-edit
rules:
  ...
```
Правила данной роли объединяются с правилами роли `edit`.

Данный механизм позволяет администратору, обладающему праву работать с ролями расширять правила роли `edit`, добавляя новые роли содержащие метку `rbac.authorization.k8s.io/aggregate-to-edit: "true"`.

## Кластерная роль admin
Кластерная роль `admin` позволяет получить полный доступ ко всем `namespace-ресурсам` во всех `namespace`'ах.
Она имеет аггрегационное правило:
```
aggregationRule:
  clusterRoleSelectors:
    - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-admin: "true"
metadata:
  name: admin  
rules:
  ...
```
которое позволяет включать в эту роль роли, имеющие в метках значение 
```
rbac.authorization.k8s.io/aggregate-to-edit: "true"
```
В предопределенных в kubernetes ролях эту метку имеет роль `system:aggregate-to-admin`:
```
metadata:
  labels:
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
  name: system:aggregate-to-admin
rules:
  ...
```
Правила данной роли объединяются с правилами роли `admin`.

Данный механизм позволяет администратору, обладающему праву работать с ролями расширять правила роли `edit`, добавляя новые роли содержащие метку `rbac.authorization.k8s.io/aggregate-to-admin: "true"`.

## Кластерная роль cluster-admin

Кластерная роль `cluster-admin` является независимой и позволяет получить полный доступ ко всем кластерным ресурсам.

## Другие кластерные роли

Имя                                                                  |  Описание
---------------------------------------------------------------------|------------------
system:auth-delegator                                                |  Позволяет в apiGroups:authentication.k8s.io создавать ресурсы tokenreviews, subjectaccessreviews 
system:basic-user                                                    | Позволяет в apiGroups:authorization.k8s.io создавать ресурсы selfsubjectaccessreviews,selfsubjectrulesreviews 
**system:certificates.k8s.io**                                       | Позволяет в apiGroups:certificates.k8s.io 
system:certificates.k8s.io:certificatesigningrequests:nodeclient     | создавать ресурс certificatesigningrequests/nodeclient
system:certificates.k8s.io:certificatesigningrequests:selfnodeclient | создавать ресурс certificatesigningrequests/selfnodeclient
system:certificates.k8s.io:kube-apiserver-client-approver            | подписывать запросы на сертификацию от kubernetes.io/kube-apiserver-client 
system:certificates.k8s.io:kube-apiserver-client-kubelet-approver    | подписывать запросы на сертификацию от kubernetes.io/kube-apiserver-client-kubelet  
system:certificates.k8s.io:kubelet-serving-approver                  | подписывать запросы на сертификацию от kubernetes.io/kubelet-serving 
system:certificates.k8s.io:legacy-unknown-approver                   | подписывать запросы на сертификацию от kubernetes.io/legacy-unknown 
**system:controller**                                                | Позволяет перемещать тома между нодами 
system:controller:attachdetach-controller                            |  
system:controller:certificate-controller                             |  
system:controller:clusterrole-aggregation-controller                 |  
system:controller:cronjob-controller                                 |  
system:controller:daemon-set-controller                              |  
system:controller:deployment-controller                              |  
system:controller:disruption-controller                              |  
system:controller:endpoint-controller                                |  
system:controller:endpointslice-controller                           |  
system:controller:endpointslicemirroring-controller                  |  
system:controller:ephemeral-volume-controller                        |  
system:controller:expand-controller                                  |  
system:controller:generic-garbage-collector                          |  
system:controller:horizontal-pod-autoscaler                          |  
system:controller:job-controller                                     |  
system:controller:namespace-controller                               |  
system:controller:node-controller                                    |  
system:controller:persistent-volume-binder                           |  
system:controller:pod-garbage-collector                              |  
system:controller:pv-protection-controller                           |  
system:controller:pvc-protection-controller                          |  
system:controller:replicaset-controller                              |  
system:controller:replication-controller                             |  
system:controller:resourcequota-controller                           |  
system:controller:root-ca-cert-publisher                             |  
system:controller:route-controller                                   |  
system:controller:service-account-controller                         |  
system:controller:service-controller                                 |  
system:controller:statefulset-controller                             |  
system:controller:ttl-after-finished-controller                      |  
system:controller:ttl-controller                                     |  
system:coredns                                                       |  
system:discovery                                                     | Позволяет просматривать API: /api, /api/*, /apis, /apis/*, /healthz, /livez, /openapi, /openapi/*, /readyz, /version, /version/
system:heapster                                                      |  
**system:kube-**                                                     |  
system:kube-aggregator                                               |  
system:kube-controller-manager                                       |  
system:kube-dns                                                      |  
system:kube-scheduler                                                |  
system:kubelet-api-admin                                             |  
system:monitoring                                                    |  
**system:node**                                                      |  
system:node                                                          |  
system:node-bootstrapper                                             |  
system:node-problem-detector                                         |  
system:node-proxier                                                  |  
system:persistent-volume-provisioner                                 |  
system:public-info-viewer                                            |  
system:service-account-issuer-discovery                              |  
system:volume-scheduler                                              | 

