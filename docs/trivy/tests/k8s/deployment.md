```
trivy k8s -n default --report summary deployments/nginx-deployment
```
<pre>
Summary Report for kubernetes-admin@kubernetes

Workload Assessment
┌───────────┬─────────────────────────────┬──────────────────────────┬────────────────────┬───────────────────┐
│ Namespace │          Resource           │     Vulnerabilities      │ Misconfigurations  │      Secrets      │
│           │                             ├────┬─────┬─────┬─────┬───┼───┬───┬───┬────┬───┼───┬───┬───┬───┬───┤
│           │                             │ C  │  H  │  M  │  L  │ U │ C │ H │ M │ L  │ U │ C │ H │ M │ L │ U │
├───────────┼─────────────────────────────┼────┼─────┼─────┼─────┼───┼───┼───┼───┼────┼───┼───┼───┼───┼───┼───┤
│ default   │ Deployment/nginx-deployment │ 57 │ 125 │ 116 │ 165 │ 7 │   │   │ 2 │ 11 │   │   │   │   │   │   │
└───────────┴─────────────────────────────┴────┴─────┴─────┴─────┴───┴───┴───┴───┴────┴───┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN
</pre>