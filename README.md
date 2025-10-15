# MITM-Lab
Lab session: the Man-in-the-Middle Attacks

## Simulated Victim Web App

This repository includes a simple Python + HTML victim site that accepts form submissions. It is meant to act as the target page during Man-in-the-Middle scenarios.

### Quick start

```bash
cd victim_site
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

The app listens on `http://127.0.0.1:8000/`. Submitting the form shows the captured information, mimicking the data that an attacker could intercept.

### Reverse proxy with Nginx

Use the provided `victim_site/nginx.conf` to forward traffic for `victim.com` to the Flask app:

```bash
sudo cp victim_site/nginx.conf /etc/nginx/conf.d/victim.conf
sudo nginx -t
sudo systemctl reload nginx
```

Ensure the Flask app is running locally on port `8000`, and update your hosts file (or DNS) so `victim.com` resolves to the machine running Nginx.
