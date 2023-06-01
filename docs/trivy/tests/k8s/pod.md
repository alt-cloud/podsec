```
trivy k8s -n default --report summary pod/nginx-deployment-6595874d85-c2tnf
```
<pre>
Summary Report for kubernetes-admin@kubernetes


Workload Assessment
┌───────────┬───────────────────────────────────────┬──────────────────────────┬────────────────────┬───────────────────┐
│ Namespace │               Resource                │     Vulnerabilities      │ Misconfigurations  │      Secrets      │
│           │                                       ├────┬─────┬─────┬─────┬───┼───┬───┬───┬────┬───┼───┬───┬───┬───┬───┤
│           │                                       │ C  │  H  │  M  │  L  │ U │ C │ H │ M │ L  │ U │ C │ H │ M │ L │ U │
├───────────┼───────────────────────────────────────┼────┼─────┼─────┼─────┼───┼───┼───┼───┼────┼───┼───┼───┼───┼───┼───┤
│ default   │ Pod/nginx-deployment-6595874d85-c2tnf │ 57 │ 125 │ 116 │ 165 │ 7 │   │   │ 3 │ 11 │   │   │   │   │   │   │
└───────────┴───────────────────────────────────────┴────┴─────┴─────┴─────┴───┴───┴───┴───┴────┴───┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN
</pre>