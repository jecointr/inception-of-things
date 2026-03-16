# P1 — K3s + Vagrant (2 VM)

Ce document te donne une procédure pas-à-pas pour terminer la partie P1 du sujet IoT.

## Recap rapide (commandes + actions)

Ce bloc te permet de faire toute la partie `ssh_authorized_keys` de bout en bout.

### Actions a faire

1. Generer (ou reutiliser) une cle SSH locale.
2. Copier la cle publique dans `p1/ssh_authorized_keys`.
3. Rejouer le provisioning Vagrant pour injecter la cle dans les 2 VM.
4. Verifier SSH sans mot de passe + verifier le check script.

### Commandes a lancer (dans PowerShell)

```powershell
cd C:\Users\ahmed\Desktop\asma-iot\iot\p1

# 1) Verifier si une cle existe deja
Test-Path $env:USERPROFILE\.ssh\id_ed25519.pub
Test-Path $env:USERPROFILE\.ssh\id_rsa.pub

# 2) Si aucune cle n'existe, en creer une
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\id_ed25519 -N ""

# 3) Remplir ssh_authorized_keys avec la cle publique
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | Set-Content .\ssh_authorized_keys

# 4) Reprovisionner les VM pour copier la cle
vagrant provision asmaS
vagrant provision asmaSW

# 5) Verifier que la cle est bien dans les VM
vagrant ssh asmaS -c "cat /home/vagrant/.ssh/authorized_keys"
vagrant ssh asmaSW -c "cat /home/vagrant/.ssh/authorized_keys"

# 6) Tester SSH sans mot de passe via IP privee
ssh -i $env:USERPROFILE\.ssh\id_ed25519 vagrant@192.168.56.110
ssh -i $env:USERPROFILE\.ssh\id_ed25519 vagrant@192.168.56.111

# 7) Verif finale P1
powershell -ExecutionPolicy Bypass -File .\scripts\check_p1.ps1 -SaveReport
```

### Modifications deja faites dans le repo

- `scripts/setup_ssh.sh`: rendu idempotent pour `authorized_keys`.
- `scripts/setup_ssh.sh`: ignore les lignes vides/commentaires de `ssh_authorized_keys`.
- `scripts/setup_ssh.sh`: evite les doublons de cles lors des reprovisionings.

## Structure attendue

- `Vagrantfile` : crée 2 VM (`<login>S` et `<login>SW`) en IP fixes.
- `scripts/setup_ssh.sh` : provisioning SSH minimal.
- `ssh_authorized_keys` : clé publique SSH à autoriser.
- `confs/` : fichiers de conf/export pour la soutenance (ex: kubeconfig, captures, logs).

## Checklist P1 (à cocher)

- [ ] P1: Vérifier Vagrant + VirtualBox
- [ ] P1: Fixer le login dans `Vagrantfile`
- [ ] P1: Préparer la clé SSH publique
- [ ] P1: Recréer les VM propres
- [ ] P1: Tester accès SSH
- [ ] P1: Installer K3s server
- [ ] P1: Récupérer token server
- [ ] P1: Installer K3s agent
- [ ] P1: Vérifier les 2 nodes
- [ ] P1: Exporter preuves (commandes + captures)

## 1) Vérifier les prérequis

Dans PowerShell (Windows):

```powershell
vagrant --version
& 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' --version
```

Si `VBoxManage` échoue, installe/répare VirtualBox avant de continuer.

## 2) Vérifier le login utilisé

Dans `Vagrantfile`, la variable `LOGIN` est actuellement:

```ruby
LOGIN = "asekmani"
```

Donc les VM attendues seront nommées `asekmaniS` et `asekmaniSW`.

## 3) Préparer la clé SSH publique

Si tu veux SSH direct vers les IP privées:

```powershell
ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\id_rsa -N ""
Get-Content $env:USERPROFILE\.ssh\id_rsa.pub
```

Copie la sortie dans le fichier `ssh_authorized_keys`.

## 4) Recréer les VM proprement

Depuis le dossier `p1`:

```powershell
cd C:\Users\ahmed\Desktop\asma-iot\iot\p1
vagrant halt
vagrant destroy -f
vagrant up
```

Important: dans cette version, `vagrant up` provisionne aussi K3s automatiquement:
- `asekmaniS` en mode server
- `asekmaniSW` en mode agent

Si tu exécutes Vagrant depuis la VM `myIOT` avec VirtualBox imbriqué, préfère cette séquence plus fiable:

```bash
cd ~/iot/p1
vagrant halt
vagrant destroy -f
VAGRANT_NO_PARALLEL=1 vagrant up asekmaniS
vagrant up asekmaniSW
```

## 5) Vérifier état et accès SSH

```powershell
vagrant status
vagrant ssh asekmaniS
vagrant ssh asekmaniSW
```

Test réseau depuis `asekmaniS`:

```bash
ping -c 3 192.168.56.111
```

## 6) K3s installé automatiquement par Vagrant

Le `Vagrantfile` lance automatiquement:
- `scripts/install_k3s_server.sh` sur `asekmaniS`
- `scripts/install_k3s_agent.sh` sur `asekmaniSW`

Tu n'as donc pas besoin de lancer l'installation manuellement en routine.

## 7) Vérifier K3s sur le server (`asekmaniS`)

Connexion:

```powershell
vagrant ssh asekmaniS
```

Depuis l'hôte (PowerShell dans `p1`) avec le script du repo:

```powershell
Get-Content .\scripts\install_k3s_server.sh | vagrant ssh asekmaniS -c "sudo bash -s"
```

Version manuelle dans la VM (si nécessaire):

```bash
curl -sfL https://get.k3s.io | sh -
sudo systemctl status k3s --no-pager
sudo kubectl get nodes -o wide
```

Commandes de vérification:

Toujours sur `asekmaniS`:

```bash
sudo systemctl status k3s --no-pager
sudo kubectl get nodes -o wide
sudo kubectl get pods -A
```

## 8) Vérifier l'agent sur `asekmaniSW`

```powershell
vagrant ssh asekmaniSW -c "sudo systemctl status k3s-agent --no-pager"
```

## 9) Vérifier cluster à 2 noeuds

Depuis `asekmaniS`:

```bash
sudo kubectl get nodes -o wide
sudo kubectl get pods -A
```

Résultat attendu: 2 noeuds en `Ready` (`asekmaniS` et `asekmaniSW`).

Si un nœud n'est pas `Ready`, relance uniquement le provisioning:

```powershell
cd C:\Users\ahmed\Desktop\asma-iot\iot\p1
vagrant provision
```

## 10) Preuves à préparer pour l'évaluation

Garde des captures/sorties de:

- `vagrant status`
- `ip a` sur chaque VM (IPs `192.168.56.110` et `192.168.56.111`)
- `sudo kubectl get nodes -o wide`
- `sudo kubectl get pods -A`
- `hostname` sur chaque VM

Tu peux stocker les exports dans `confs/`.

## Script de vérification automatique

Un script PowerShell est disponible: `scripts/check_p1.ps1`.

Exécution simple:

```powershell
cd C:\Users\ahmed\Desktop\asma-iot\iot\p1
powershell -ExecutionPolicy Bypass -File .\scripts\check_p1.ps1
```

Exécution + rapport sauvegardé dans `confs/`:

```powershell
cd C:\Users\ahmed\Desktop\asma-iot\iot\p1
powershell -ExecutionPolicy Bypass -File .\scripts\check_p1.ps1 -SaveReport
```

---

## Dépannage rapide

- Erreur hostname: éviter `_` (caractères autorisés: lettres, chiffres, `-`, `.`).
- `vagrant ssh <name>` introuvable: vérifier `vagrant status` et utiliser le nom exact.
- Si `vagrant up` bloque: redémarrer Windows après installation VirtualBox.
