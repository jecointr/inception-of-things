# P2 - K3s + 3 applications (Ingress)

Ce dossier implemente la partie P2 du sujet IoT avec:
- la base de `p1` (2 VM): `asekmaniS` server + `asekmaniSW` worker
- 3 applications web avec IHM, images Docker pretes, sans base de donnees
- Routage Ingress par host:
  - `app1.com` -> app1
  - `app2.com` -> app2 (3 replicas)
  - host non reconnu -> app3 (default backend)

## Structure

- `Vagrantfile`: base `p1` avec server + worker
- `scripts/setup_ssh.sh`: prepare SSH
- `scripts/install_k3s_server.sh`: installe K3s server
- `scripts/install_k3s_agent.sh`: installe K3s agent
- `manifests/00-namespace/namespace.yaml`
- `manifests/app1/`: `deployment.yaml`, `service.yaml`
- `manifests/app2/`: `deployment.yaml`, `service.yaml`
- `manifests/app3/`: `deployment.yaml`, `service.yaml`
- `manifests/ingress/app1-ingress.yaml`
- `manifests/ingress/app2-ingress.yaml`
- `manifests/ingress/app3-default-ingress.yaml`

## 1) Lancer la VM P2

Depuis PowerShell:

```powershell
cd C:\Users\ahmed\Desktop\asma-iot\iot\p2
vagrant up
vagrant status
```

Note: pendant `vagrant up`, toutes les ressources Kubernetes P2 (namespace, deployments, services, ingress) sont deployees automatiquement.
Ce deploiement est lance par un trigger scope sur le worker (`asekmaniSW`) apres son provisioning, puis attend que ce node soit `Ready` avant application.

## 2) Verifier K3s

```powershell
vagrant ssh asekmaniS -c "sudo systemctl is-active k3s"
vagrant ssh asekmaniSW -c "sudo systemctl is-active k3s-agent"
vagrant ssh asekmaniS -c "sudo kubectl get nodes -o wide"
```

## 3) Redeployer les ressources (si modification des manifests)

```powershell
vagrant provision asekmaniS
vagrant ssh asekmaniS -c "sudo P2_MANIFESTS_DIR=/tmp/p2_manifests bash /tmp/install_p2_manifests.sh"
```

## 4) Verifier le deploiement

```powershell
vagrant ssh asekmaniS -c "sudo kubectl get all -n iot-p2"
vagrant ssh asekmaniS -c "sudo kubectl get ingress -n iot-p2"
```

Attendu:
- `app1` en 1 pod
- `app2` en 3 pods
- `app3` en 1 pod

## 5) Tester le routage Ingress

### Option A: test rapide depuis la VM avec curl + Host header

```powershell
vagrant ssh asekmaniS -c "curl -s -H 'Host: app1.com' http://192.168.56.110 | head -n 5"
vagrant ssh asekmaniS -c "curl -s -H 'Host: app2.com' http://192.168.56.110 | head -n 5"
vagrant ssh asekmaniS -c "curl -s -H 'Host: anything-else.com' http://192.168.56.110 | head -n 5"
```

### Option B: test navigateur depuis Windows

Ajoute ces lignes dans `C:\Windows\System32\drivers\etc\hosts`:

```txt
192.168.56.110 app1.com
192.168.56.110 app2.com
192.168.56.110 app3.com
```

Puis ouvre:
- `http://app1.com`
- `http://app2.com`
- `http://app3.com` (tombe sur app3 via backend par defaut)

## 6) Commandes de preuve pour la soutenance

```powershell
vagrant status
vagrant ssh asekmaniS -c "hostname"
vagrant ssh asekmaniSW -c "hostname"
vagrant ssh asekmaniS -c "ip a show"
vagrant ssh asekmaniSW -c "ip a show"
vagrant ssh asekmaniS -c "sudo kubectl get nodes -o wide"
vagrant ssh asekmaniS -c "sudo kubectl get pods -n iot-p2 -o wide"
vagrant ssh asekmaniS -c "sudo kubectl get svc,ingress -n iot-p2"
```

## Notes

- App1 utilise `cnrock/2048:latest`.
- App2 utilise `lrakai/tetris:latest` (3 replicas).
- App3 utilise `rmeira/chess:latest` (default backend).
- Les 3 apps utilisent des images pretes a l'emploi, sans montage de volume dans les pods.
- Pas de base de donnees, conformement a ta contrainte.
- `app2` est explicitement configuree avec `replicas: 3` pour respecter le sujet.
