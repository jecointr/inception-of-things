const APP_VERSION = '__APP_VERSION__';

const content = {
  v1: {
    badge: 'v1 🚀',
    accent: '#2ec4b6',
    jokes: [
      "Why did the pod restart? It needed emotional support from ReplicaSet.",
      "Argo CD never forgets. It just reconciles your mistakes.",
      "Traefik is the bouncer. Wrong host header? Not tonight.",
      "If it works on localhost, commit before it changes its mind.",
      "K3d: tiny cluster, huge confidence."
    ]
  },
  v2: {
    badge: 'v2 ✨',
    accent: '#e040fb',
    jokes: [
      "GitLab local: because trust issues with GitHub are valid.",
      "Argo CD synced. Your sanity: less so.",
      "kubectl apply -f life.yaml — still Pending.",
      "The YAML is fine. The indentation is fine. Nothing is fine.",
      "Kubernetes: turning simple problems into distributed ones."
    ]
  }
};

const v = content[APP_VERSION] || content.v1;

// Apply accent color
document.documentElement.style.setProperty('--accent', v.accent);

const elJoke = document.getElementById('joke');
const elVer = document.getElementById('version');
const elBtn = document.getElementById('btn');

function pickJoke() {
  const i = Math.floor(Math.random() * v.jokes.length);
  elJoke.textContent = v.jokes[i];
}

elVer.textContent = `version: ${v.badge}`;
elBtn.addEventListener('click', pickJoke);
pickJoke();
