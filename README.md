Inception-of-Things (IoT) - repository

Structure créée:
- p1/ : Vagrant + scripts pour préparer 2 VM (Server, ServerWorker)
- p2/ : manifests pour 3 applications et ingress
- p3/ : scripts pour k3d et ArgoCD
- bonus/: dossier optionnel pour GitLab local

Suivant:
- Remplis `p1/ssh_authorized_keys` avec ta clé publique et remplace TON_LOGIN dans `p1/Vagrantfile`.
- Exécute `vagrant up` depuis `p1` pour lancer les VM.
- Je peux maintenant générer les scripts d'installation K3s et les manifests restants si tu veux.
