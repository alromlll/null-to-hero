# 🖥️ Homelab Journal

> Documentación de mi homelab personal — Road to autodidacta Sysadmin Junior
> Roadmap: X semanas | Inicio: Febrero 2026

---

## 📌 Objetivo

Conseguir mi primer empleo en IT (Soporte N1/N2 → Junior Sysadmin) mediante práctica real en homelab, documentación pública y certificación LPIC-1.

Sin estudios formales. Con infraestructura real, scripts reales y documentación real.

---

## 🔧 Hardware

| Máquina       | Rol                        | OS                        |
|---------------|----------------------------|---------------------------|
| Laptop        | Estación de trabajo / SSH  | Arch Linux                |
| PC (Proxmox)  | Hipervisor / VMs / CTs     | Proxmox VE                |
| Raspberry Pi 4 (2GB) | Servicios ligeros   | Raspberry Pi OS Lite      |

---

## 🌐 Diagrama de red

```
Internet
    │
[Router] — 192.168.1.1
    │
[Switch]
    ├── Laptop         192.168.1.X   (Arch Linux)
    ├── Proxmox        192.168.1.Y   (Hipervisor)
    │     ├── VM-01    192.168.1.W   (Ubuntu Server 22.04)
    │     ├── VM-02    192.168.1.V
    │     └── VM-...   (futuras VMs)
    └── Raspberry Pi   192.168.1.Z   (RPi OS Lite)
```

> Las IPs estáticas se configurarán y actualizará este diagrama con los valores reales.

---

## 🗺️ Roadmap — 14 semanas

| Fase | Semanas | Contenido |
|------|---------|-----------|
| Fase 0 | 1 | Preparación del entorno + GitHub |
| Fase 1 | 2–4 | Linux sólido: permisos, almacenamiento, Bash |
| Fase 2 | 5–7 | Redes: IP estática, DNS, firewall, SSH |
| Fase 3 | 8–10 | Servicios: Nginx, Docker, monitorización |
| Fase 4 | 11–14 | Certificación LPIC-1 + portfolio + entrevistas |

---

## 🛠️ Stack de herramientas (objetivo final)

| Herramienta     | Estado       |
|-----------------|--------------|
| Terminal Linux  | ✅️ Completado|
| Bash scripting  | ✅️ Completado|
| SSH             | ✅️ Activo    |
| Nginx           | ✅️ Pendiente |
| Docker          | ⬜ Pendiente |
| Proxmox         | ✅️ Activo    |
| Git / GitHub    | ✅ Activo    |
| Firewall (ufw)  | ⬜ Pendiente |
| DNS / DHCP      | ⬜ Pendiente |
| Monitorización  | ✅️ Pendiente |

> Se irá actualizando semana a semana conforme se completen los módulos.

---

## 📁 Estructura del repositorio

```
homelab-journal/
├── README.md              ← este archivo
├── proxmox/               ← configuración y notas de VMs
├── scripts/               ← scripts Bash reales
├── networking/            ← configs de DNS, firewall, SSH
├── docker/                ← docker-compose y notas
├── monitoring/            ← Grafana, alertas
└── docs/                  ← Practicas, recursos y guias
```

---

## 📅 Progreso semanal

| Semana | Estado | Entregable |
|--------|--------|------------|
| 1 — Preparación | ✅ Completado | README + Proxmox con VM corriendo |
| 2 — Permisos y servicios | ✅️ Completado | Guía de permisos en GitHub |
| 3 — Almacenamiento | ✅️ Completado | Disco montado + lsblk/df -h |
| 4 — Bash scripting | ✅️ | En curso | 3 scripts + crontab |
| 5 — Redes básicas | ✅️ | Diagrama de red + IPs estáticas |
| 6 — Servicios de red | 🔄 | DNS propio + firewall |
| 7 — SSH profesional | ⬜ | SSH por clave + fail2ban |
| 8 — Nginx + reverse proxy | ⬜ | Web servida + Pi-hole |
| 9 — Docker | ⬜ | WordPress + MySQL en Docker |
| 10 — Monitorización | ⬜ | Dashboard + alertas |
| 11–12 — LPIC-1 | ⬜ | Estudio intensivo |
| 13 — Portfolio | ⬜ | GitHub organizado + LinkedIn |
| 14 — Entrevistas | ⬜ | Prep técnica y soft skills |

---

*Última actualización: Semana 3/4 — Febrero 2026*
