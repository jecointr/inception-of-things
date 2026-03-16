# p3 - K3d and Argo CD

Cette partie met en place un cluster K3d, Argo CD, et un deploiement GitOps d'une application dans le namespace `dev`.

## Structure

- `scripts/install_tools_create_k3d_cluster_and_bootstrap_argocd.sh`: script principal de soutenance (installe outils, cree le cluster, puis lance le bootstrap Argo CD/GitOps).
- `scripts/bootstrap_argocd_and_apply_gitops_app.sh`: script de bootstrap Argo CD + Application GitOps (utile aussi en relance manuelle).
- `confs/argocd/application-template.yaml`: exemple de ressource `Application` Argo CD.

## Prerequis

- Une VM Debian/Ubuntu (partie 3 sans Vagrant, conformement au sujet).
- Acces internet depuis la VM.
- Un repo GitHub public avec le login d'un membre dans le nom du repo.

## 1) Script unique (installation complete P3)

Depuis `p3/`:

```bash
sudo bash scripts/install_tools_create_k3d_cluster_and_bootstrap_argocd.sh
kubectl get nodes -o wide
```

Le script cree un cluster `iot`, expose Traefik sur `localhost:8888`, installe Argo CD, puis applique l'Application GitOps.

## 2) Source GitOps (repoURL)

Le script applique directement `confs/argocd/application-template.yaml`.
Argo CD deploie ensuite les manifests depuis le repo defini dans `repoURL` (et le `path` associe).
Si besoin, ajuste `repoURL`, `targetRevision` ou `path` dans ce fichier avant execution.

Verifications:

```bash
kubectl get ns
kubectl -n argocd get pods
kubectl -n argocd get applications.argoproj.io
kubectl -n dev get deploy,svc,pods
```

## 3) Acceder a Argo CD (UI)

### Option A - Ingress (recommande)

Le bootstrap applique `confs/argocd/argocd-ingress.yaml` avec l'hote:

- `https://argocd.192.168.56.120.nip.io:8888`

`nip.io` resolve automatiquement vers l'IP incluse dans le hostname.

### Option B - Port-forward

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

- URL: `https://localhost:8080`
- User: `admin`
- Password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
```

## 4) Demonstration v1 -> v2 (obligatoire)

### Etape A: confirmer v1

Dans ton repo GitHub, `deployment.yaml` doit contenir:

```yaml
image: wil42/playground:v1
```

Puis dans la VM:

```bash
kubectl -n dev get pods
kubectl -n dev port-forward svc/playground 8888:8888
curl http://localhost:8888/
```

Reponse attendue: message `v1`.

### Etape B: passer en v2 via GitHub

1. Modifie dans ton repo public:

```yaml
image: wil42/playground:v2
```

2. Commit + push.
3. Attends la synchro Argo CD (UI ou `kubectl -n argocd get applications.argoproj.io`).
4. Re-teste:

```bash
curl http://localhost:8888/
```

Reponse attendue: message `v2`.

## Commandes utiles soutenance

```bash
kubectl get ns
kubectl -n argocd get pods
kubectl -n dev get all
kubectl -n argocd get applications.argoproj.io -o wide
kubectl -n dev describe deploy playground
```

## Notes

- Le sujet demande un repo GitHub public comme source Argo CD (pas un dossier local).
- Si `docker` est installe pendant la session courante, relance ton shell (ou `newgrp docker`) avant d'utiliser `k3d` sans `sudo`.
