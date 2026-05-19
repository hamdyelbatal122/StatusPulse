# 📊 StatusPulse: Bash-Driven Service Health Dashboard

<p align="center">
  <a href="https://www.gnu.org/software/bash/">
    <img src="https://img.shields.io/badge/Made%20with-Bash-1f425f.svg" alt="Made with Bash" />
  </a>
  <a href="https://developer.mozilla.org/en-US/docs/Web/HTML">
    <img src="https://img.shields.io/badge/UI-HTML5%20%26%20CSS3-brightgreen.svg" alt="HTML5 & CSS3" />
  </a>
  <a href="https://unlicense.org/">
    <img src="https://img.shields.io/badge/License-Unlicense-blue.svg" alt="Unlicense" />
  </a>
</p>

---

## 🌐 Overview
**StatusPulse** is a lightweight, high-performance service monitoring dashboard designed to audit endpoints and application health states. Built with highly optimized shell scripts (`Bash`) and compiled directly into beautiful, chronological SVG grids, the system does not require any database engine, containerized micro-runtime, or bulky framework dependencies. It integrates a premium, dark-themed, glassmorphic Web user interface to render historical status timelines with pixel-perfect visual styling.

---

## 🚀 Key Features & Architecture

* **Zero DB Dependency**: Employs standardized Linux system cron scheduling to audit endpoints and render state indicators into local static SVG graphics.
* **Premium Glassmorphic Dashboard**: A high-end dark slate dashboard (`#0b0f19`) featuring ambient neon gradient backgrounds, soft borders, and smooth glowing micro-animations.
* **SVG Visual Matrix**: Generates a timeline visualization where columns represent hours of the day (30-min granular steps) and rows represent target application endpoints.
* **Live DOM Analytics Parser**: The responsive parent dashboard dynamically calculates overall uptime percentages, active healthy endpoints, and critical alarms in real time by directly parsing the loaded SVG iframe.
* **Syntactically Valid SVG Engine**: A modern line-stripping algorithm in `addtile.sh` guarantees W3C-compliant HTML/SVG rendering throughout the auditing lifecycle.

---

## 🛠️ How It Works

1. **Daily Initialization (`indexcreator.sh`)**: Executed once daily (typically at `00:00`) to reset the daily visual canvas (`today.html`), establish the SVG matrix coordinate grid height, print timeline hour markers, and map the targets.
2. **Status Audit Agent (`addtile.sh`)**: Executed at regular short-term intervals (e.g., every 30 mins) to perform HTTP GET handshake validations against target endpoints and append visual color-coded node tiles (emerald for pass, crimson for fail, amber for warning).
3. **Directory Bootstrapper (`dir_setup.sh`)**: Organizes child subdirectory structures and bootstraps start configurations for granular multi-tenant instance views.

---

## ⚙️ Quick Start Guide

### 1. Installation & Workspace Setup
Clone the repository and prepare the configurations:
```bash
git clone https://github.com/hamdyelbatal122/shell-Mon_Application.git
cd shell-Mon_Application
mkdir -p config
touch config/app.conf
```

### 2. Configure Monitored Endpoints
Define target components and URLs inside `config/app.conf` in a clean `Component-Name,Url` comma-separated matrix:
```text
Payment-Gateway,api.payment.example.com
Database-Cluster,db.cluster.example.com
Authentication-Service,auth.example.com/version.html
```

### 3. Initialize & Audit
Generate the daily grid frame template:
```bash
./indexcreator.sh a
```

Trigger a manual status audit sweep:
```bash
./addtile.sh a
```

---

## ⏰ Cron Integration (Production Setup)

Automate StatusPulse by setting up standard Linux system cron scheduling. Open your cron editor (`crontab -e`) and append the following configurations:

```text
# 1. Initialize the dashboard grid canvas daily at midnight (00:00)
0 0 * * * /home/hamdy/Desktop/Github/shell-Mon_Application/indexcreator.sh a

# 2. Audit and update endpoint status tiles twice an hour (at the 1st and 31st minutes)
1,31 * * * * /home/hamdy/Desktop/Github/shell-Mon_Application/addtile.sh a
```

*Note: Verify that paths point to your absolute directory location.*

---

## 📊 SVG Tile Colors & Status Tokens
* **🟢 Healthy Node (`.pass`)**: HTTP 200 OK received, version parsed successfully. Highlighted with a glowing emerald hue (`#10b981`).
* **🔴 Critical Node (`.fail`)**: Connection timeout or error status code. Highlighted with a glowing crimson hue (`#ef4444`).
* **🟡 Warning State (`.warn`)**: Intermittent parsing discrepancies or customized warnings. Highlighted with an amber hue (`#f59e0b`).
* **⚫ Pending State (`.status`)**: Scheduled slots awaiting execution. Neutral dark slate color (`#1e293b`).

---

## 📝 Roadmap & Future Enhancements
* [x] **Visual Redesign**: Sleek glassmorphic layout, Outfit typography, and custom ambient neon glows.
* [x] **Dynamic Real-time Uptime**: Automatic JS parser to calculate overall healthy/critical node metrics.
* [x] **W3C Valid SVG Generator**: Prevent SVG syntax breaks during cron appends.
* [ ] **Email Alerts Integration**: Optional alert dispatcher to notify operators instantly upon critical failures.
* [ ] **Interactive Hover Tooltips**: Advanced mouse-over card indicators directly inside the SVG frames.

---

## ⚖️ License
This project is dedicated to the public domain under the terms of the [Unlicense](LICENSE). You are free to copy, modify, compile, publish, and distribute this software for any purpose, commercial or non-commercial.
