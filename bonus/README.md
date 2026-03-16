# Bonus - GitLab local sur P3

## Objectif

Le bonus part de P3 et ajoute GitLab local dans le cluster.
Argo CD ne lit plus GitHub directement: il lit un repo GitLab local.

## Prerequis

- P3 deja operationnel
- kubectl configure sur le cluster
- VM assez puissante (minimum conseille: 4 Go RAM, 2 CPU)

## Configuration centralisee

Toutes les valeurs sont dans:

`confs/bonus.env`

Variables principales:

- `GITLAB_PASSWORD`: password de root (par défaut: `root`)
- `GITLAB_TOKEN`: optionnel (pour création auto du project, sinon créer manuellement)
- `DOCKERHUB_IMAGE`: image Docker Hub utilisée (par défaut: `asekmani/iot-funny`)

## Workflow d'installation (2 phases)

### Phase 1: Setup de l'infrastructure GitLab

```bash
bash scripts/1-setup-gitlab-infrastructure.sh
```

Cette phase:
- Vérifie les prérequis (kubectl, helm, etc.)
- Crée les namespaces (`gitlab`, `argocd`, `dev`)
- Installe GitLab avec Helm
- Attend que GitLab soit opérationnel
- Affiche les URLs et credentials

**⏸️ PAUSE MANUELLE**: Après cette étape, le script affiche les credentials. Ensuite:

**Récupérer le mot de passe initial:**
```bash
kubectl -n gitlab get secret gitlab-gitlab-initial-root-password \
  -o jsonpath='{.data.password}' | base64 --decode
```

**1. Se connecter à GitLab:**
- URL: `http://gitlab.192.168.56.120.nip.io:8888`
- Login: `root` / mot de passe récupéré ci-dessus

**2. Créer le projet `iot-funny`:**
- New project → Create blank project
- Name: `iot-funny`, Visibility: `Public`, décocher *Initialize README*

**3. Créer un Access Token (optionnel, pour automatiser):**
- Profile → Access Tokens → nom: `bonus`, scopes: `api` + `write_repository`
- Copier le token dans `confs/bonus.env` → `GITLAB_TOKEN`

> Sans token, le script `45` utilisera git push avec username/password.

### Phase 2: Setup de l'application avec Argo CD

Une fois le projet créé manuellement, lancer:

```bash
bash scripts/2-setup-argocd-application.sh
```

Cette phase:
- Push le code funny-app et les manifests vers GitLab
- Enregistre le repo dans Argo CD
- Applique l'Application Argo CD
- Configure les ingress routes
- Vérifie que tout est OK

## Détail des étapes

**Phase 1** (00-40):
- `00_check_prereqs.sh`: vérifie outils et accès cluster
- `10_create_namespaces.sh`: crée namespaces
- `20_install_gitlab.sh`: installe GitLab avec Helm
- `30_wait_gitlab.sh`: attend readiness GitLab
- `40_show_gitlab_access.sh`: affiche URLs + credentials

**Phase 2** (45-90):
- `45_push_funny_app_to_gitlab.sh`: push funny-app + manifests vers GitLab
- `50_register_gitlab_repo_in_argocd.sh`: crée secret repository dans Argo CD
- `60_apply_argocd_gitlab_app.sh`: applique Application Argo CD
- `65_apply_argocd_ingress.sh`: configure ingress pour Argo CD
- `90_verify_bonus.sh`: verifications finales

## Projet funny-app

Mini projet web dans `funny-app/`:

- `Dockerfile`: build avec version v1/v2 (via ARG VERSION)
- `app.js`: contenu différent selon version (v1=teal, v2=violet)
- `styles.css`: CSS avec variable `--accent`
- `manifests/`: Kubernetes resources (deployment, service, ingress, namespace)

L'image Docker Hub utilisée est configurable via `DOCKERHUB_IMAGE` dans `bonus.env`.

## Étapes de DEMO

Une fois le setup complet:

### 1️⃣ Vérifier l'état du cluster

```bash
# Vérifier que les namespaces existent
kubectl get namespaces

# Vérifier GitLab
kubectl -n gitlab get pods

# Vérifier Argo CD
kubectl -n argocd get pods

# Vérifier l'application
kubectl -n dev get all
```

### 2️⃣ Accéder aux applications

- **App v1**: `http://funny.192.168.56.120.nip.io:8888`
- **Argo CD**: `http://argocd.192.168.56.120.nip.io:8888`
- **GitLab**: `http://gitlab.192.168.56.120.nip.io:8888`

### 3️⃣ Vérifier l'Application Argo CD

```bash
# Vérifier l'Application
kubectl -n argocd get applications

# Détails de l'Application
kubectl -n argocd describe application iot-funny-gitlab
```

### 4️⃣ Montrer la synchronisation GitOps

Dans Argo CD UI:
- Vérifier que l'Application est en sync
- Voir le graphe de ressources
- Montrer que les manifests viennent de GitLab

### 5️⃣ Basculer de version (GitOps demo)

Edit le fichier `manifests/deployment.yaml` directement dans GitLab UI:
- Remplacer `asekmani/iot-funny:v1` par `asekmani/iot-funny:v2`
- Commit et push
- Argo CD synchronise automatiquement (~30s)
- L'app change (couleur de fond: teal → violet)

Ou via git depuis la VM:
```bash
# Clone le repo depuis GitLab
git clone http://root:<PASSWORD>@gitlab.192.168.56.120.nip.io:8888/root/iot-funny.git /tmp/iot-funny
cd /tmp/iot-funny

# Changer la version
sed -i 's|asekmani/iot-funny:v1|asekmani/iot-funny:v2|g' manifests/deployment.yaml

# Push
git add manifests/deployment.yaml
git commit -m "chore: bump to v2"
git push
```

## URLs utiles

- **GitLab**: `http://gitlab.192.168.56.120.nip.io:8888`
- **Argo CD**: `http://argocd.192.168.56.120.nip.io:8888`
- **App funny**: `http://funny.192.168.56.120.nip.io:8888`

## Troubleshooting

```bash
# Vérifier logs GitLab
kubectl -n gitlab logs -l app.kubernetes.io/name=gitlab --tail=50

# Vérifier logs Argo CD
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-server --tail=50

# Vérifier logs Application
kubectl -n dev logs -l app=funny --tail=50
```

