# Validation instructions

## 1. Deploy

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

## 2. Validate the MySQL StatefulSet

```bash
# 3 pods: mysql-0, mysql-1, mysql-2, all Running and 1/1 Ready
kubectl get pods -n mysql

# StatefulSet is 3/3
kubectl get statefulset -n mysql

# Headless service (CLUSTER-IP must be None)
kubectl get svc -n mysql

# One PVC per pod: data-mysql-0, data-mysql-1, data-mysql-2
kubectl get pvc -n mysql

# Secrets are injected (names only, values are not printed here)
kubectl get secret mysql-secrets -n mysql

# Probes and resources are set
kubectl describe pod mysql-0 -n mysql | grep -E "Liveness|Readiness|Limits|Requests" -A2
```

## 3. Validate init.sql ran

```bash
kubectl exec -n mysql mysql-0 -- mysql -uapp_user -p1234 app_db -e "SHOW TABLES;"
```

Expected output contains the `counter` table.

## 4. Validate the headless service DNS (mysql-0)

```bash
kubectl run -it --rm dns-test --image=busybox:1.36 --restart=Never -n todoapp -- \
  nslookup mysql-0.mysql.mysql.svc.cluster.local
```

## 5. Validate the application

```bash
kubectl get pods -n todoapp
kubectl logs -n todoapp deploy/todoapp

# Env vars come from the Secret (NAME, USER, PASSWORD, HOST)
kubectl exec -n todoapp deploy/todoapp -- printenv HOST NAME USER

kubectl port-forward -n todoapp deploy/todoapp 8080:8080
# in another terminal:
curl -i http://localhost:8080/api/health
curl -i http://localhost:8080/api/ready
```

Open http://localhost:8080 and use the app; the counter is stored in `mysql-0`.

## 6. Validate persistence

```bash
kubectl delete pod mysql-0 -n mysql
kubectl wait --for=condition=Ready pod/mysql-0 -n mysql --timeout=300s
kubectl exec -n mysql mysql-0 -- mysql -uapp_user -p1234 app_db -e "SELECT * FROM counter;"
```

Data is still there after the pod is recreated.

## 7. Cleanup

```bash
kind delete cluster --name todoapp
```