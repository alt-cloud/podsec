# Полезные ссылки и команды для RBAC

* [Как работает RBAC в Kubernetes](https://habr.com/ru/company/southbridge/blog/655409/)
  - Service Account Tokens 
Как создать токен для serviceaccount
<pre>
kubectl create serviceaccount kaf
kubectl create token kaf
</pre>  

* [Kubernetes Authenticating](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)
  - [Посмотреть содержимое JWT-токена](https://jwt.io/)
echo $token | jq -R 'split(".") | .[0],.[1] | @base64d | fromjson'

* [Access Clusters Using the Kubernetes API](https://kubernetes.io/docs/tasks/administer-cluster/access-cluster-api/)
  - [Directly accessing the REST API](https://kubernetes.io/docs/tasks/administer-cluster/access-cluster-api/#using-kubectl-proxy)

* [A few steps are required in order to get a normal user to be able to authenticate and invoke an API](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-private-key)

* [Configure RBAC in your Kubernetes Cluster](https://docs.bitnami.com/tutorials/configure-rbac-in-your-kubernetes-cluster/)

* [Понимаем RBAC в Kubernetes](https://habr.com/ru/company/flant/blog/422801/)

* [RBAC Authorization selectel](https://docs.selectel.ru/cloud/managed-kubernetes/clusters/rbac-authorization/)

* [cURLing the Kubernetes API server](https://nieldw.medium.com/curling-the-kubernetes-api-server-d7675cfc398c)

* [Authenticating Users in Kubernetes](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)

* [Генерация сертификатов вручную](https://kubernetes.io/ru/docs/tasks/administer-cluster/certificates/)

* [Создание пользователя, ролей и контекста!!!](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/#create-private-key)