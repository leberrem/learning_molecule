# MOLECULE

## Installation

```shell
sudo apt-get install -y python-pip libssl-dev
sudo pip install --upgrade --user setuptools
pip install --user molecule
pip install 'molecule[docker]'
```

## 1. Création du rôle

* Création du role

```shell
molecule init role --verifier-name goss --role-name maj_cert
cd maj_cert
molecule test
```

* Mise à jour des meta

<details><summary>meta/main.yml</summary>
<p>

```yml
---
galaxy_info:
  author: Mikaël LE BERRE
  description: Configuration des certificats HAProxy
  company: MLB
  license: Private
  min_ansible_version: 1.2
  platforms:
  - name: Centos
    versions:
    - 7
  - name: Ubuntu
    versions:
    - 16.04
  galaxy_tags: []
dependencies: []
```

</p>
</details>


> utiliser `goss` à la place de `testinfra` par défaut pour tester via ansible<br>
> <https://github.com/aelsabbahy/goss/blob/master/docs/manual.md>

## 2. Intégration du code du role

Remplacement de `main.yml` du repertoire `tasks` par le fichier du role `legacy`

```shell
molecule lint
```

## 3. Preparation environnement

Création d'un fichier `prepare.yml` qui installe et configure haproxy pour test
Enplacement `molecule`>>>`default`>>>`prepare.yml`
Création du dossier et fichiers de ressources:

* resources/
* resources/200.http
* resources/503.http
* resources/create_certificate.sh
* resources/haproxy.cfg
* resources/test.pem
* resources/test2.pem

<details><summary>prepare.yml</summary>
<p>

```yml
---

- name: "Prepare"
  hosts: all
  become: yes

  vars:
    haproxy_dir: "/etc/haproxy"

  tasks:
    - name: "Prepare : Install haproxy"
      package:
        name: "haproxy"
        state: present

    - name: "Prepare : Install openssl"
      package:
        name: "openssl"
        state: present

    - name: "Prepare : generate certificate"
      shell: |
        openssl genrsa -out {{ haproxy_dir }}/default.key 2048
        openssl req -new -key {{ haproxy_dir }}/default.key -out {{ haproxy_dir }}/default.csr -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=default.com"
        openssl x509 -req -days 365 -in {{ haproxy_dir }}/default.csr -signkey {{ haproxy_dir }}/default.key -out {{ haproxy_dir }}/default.crt
        cat {{ haproxy_dir }}/default.key {{ haproxy_dir }}/default.crt > {{ haproxy_dir }}/default.pem

    - name: "Prepare : copy resources"
      copy:
        src: "{{ item }}"
        dest: "{{ haproxy_dir }}"
      with_items:
        - resources/200.http
        - resources/503.http
        - resources/haproxy.cfg

    - name: "Prepare : reload Haproxy configuration"
      service:
        name: "haproxy"
        state: reloaded
```

</p>
</details>

<details><summary>resources/</summary>
<p>

```html
mkdir -p molecule/default/resources
```

</p>
</details>

<details><summary>200.http</summary>
<p>

```html
HTTP/1.0 200 OK
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<html>
    <title>200 OK</title>
    <body>
        <h1>200 OK</h1>
    </body>
</html>
```

</p>
</details>

<details><summary>503.http</summary>
<p>

```html
HTTP/1.0 503 Service Unavailable
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<html>
    <title>503 Service Unavailable</title>
    <body>
        <h1>503 Service Unavailable</h1>
    </body>
</html>
```

</p>
</details>

<details><summary>haproxy.cfg</summary>
<p>

```ini
global
    log         127.0.0.1 len 4096 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    tune.ssl.default-dh-param 2048
    ssl-default-bind-ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA
    ssl-default-bind-options no-sslv3

defaults
    mode        http
    log         global
    option      httplog
    timeout     http-request 10s
    timeout     queue 1m
    timeout     connect 10s
    timeout     client 1m
    timeout     server 7200s
    timeout     http-keep-alive 10s
    timeout     check 10s
    maxconn     5000
    errorfile   503 /etc/haproxy/503.http

frontend web
    bind *:80
    redirect scheme https if !{ ssl_fc }
    default_backend b_default

frontend webssl
    bind *:443 ssl crt /etc/haproxy/default.pem no-sslv3
    http-request set-header X-Forwarded-Proto https if { ssl_fc }
    capture request header User-Agent len 20
    default_backend b_default

backend b_default
    errorfile 503 /etc/haproxy/200.http
```

</p>
</details>

```shell
molecule create
```

## 4. Correction du problème préparation

Modification de la construction du conteneur pour supporter `systemd`

<details><summary>molecule/molecule.yml</summary>
<p>

```yml
---
dependency:
  name: galaxy
driver:
  name: docker
lint:
  name: yamllint
platforms:
  - name: instance
    image: centos:7
    # --- systemd ---
    command: /sbin/init
    tmpfs:
      - /run
      - /tmp
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
provisioner:
  name: ansible
  lint:
    name: ansible-lint
verifier:
  name: goss
  lint:
    name: yamllint
```

</p>
</details>

```shell
molecule destroy
molecule create
```

## 5. Refactoring et certificats

* Utilisation des dossiers `vars` et `default`
* Refactoring et utilisation d'une boucle sur les certificats
* Generation des certificats à uploader
* Ajout de paramètres au lancement du rôle

<details><summary>vars/main.yml</summary>
<p>

```yml
---
cert_files: []
```

</p>
</details>

<details><summary>defaults/main.yml</summary>
<p>

```yml
---
certs_dir: "/etc/haproxy"
```

</p>
</details>

<details><summary>tasks/main.yml</summary>
<p>

```yml
---
- name: "Copy ssl cert for web server"
  copy:
    src: "{{ item.folder }}/{{ item.filename }}"
    dest: "{{ certs_dir }}/{{ item.filename }}"
  with_items:
    - "{{ cert_files }}"

- name: "Reload Haproxy configuration"
  service:
    name: "haproxy"
    state: reloaded
```

</p>
</details>

<details><summary>Création des certificats</summary>
<p>

script `molecule/default/resources/create_certificate.sh` d'aide à la génération des certificats
```shell
#!/bin/bash

if [ -z $1 ]; then
    echo "please enter certificate name as parameter"
    echo "create_certificate.sh default"
    exit 1
else
    name=$1
fi

validity=11499

openssl genrsa -out ${name}.key 2048
openssl req -new -key ${name}.key -out ${name}.csr -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=${name}.com"
openssl x509 -req -days ${validity} -in ${name}.csr -signkey ${name}.key -out ${name}.crt
cat ${name}.key ${name}.crt > ${name}.pem

rm -f ${name}.crt ${name}.csr ${name}.key

openssl x509 -enddate -noout -in ${name}.pem
```

Generation des certificats
```shell
cd molecule/default/resources
sh ./create_certificate.sh test
sh ./create_certificate.sh test2
cd -
```

</p>
</details>

<details><summary>molecule/playbook.yml</summary>
<p>

```yml
---
- name: Converge
  hosts: all
  roles:
    - role: maj_cert
      cert_files:
        - filename: "test.pem"
          folder: "resources"
        - filename: "test2.pem"
          folder: "resources"
```

</p>
</details>

```shell
molecule converge
molecule idempotence
```

## 6. Gestion de l'idempotence

```shell
molecule converge
```
> TASK [maj_cert : Reload Haproxy configuration] *********************************<br>
`changed`: [instance]

* Déporter le reload de haproxy dans un `handler`

<details><summary>handlers/main.yml</summary>
<p>

```yml
---
- name: "Reload Haproxy configuration"
  service:
    name: "haproxy"
    state: reloaded
```

</p>
</details>

<details><summary>tasks/main.yml</summary>
<p>

```yml
---
- name: "Copy ssl cert for web server"
  copy:
    src: "{{ item.folder }}/{{ item.filename }}"
    dest: "{{ certs_dir }}/{{ item.filename }}"
  with_items:
    - "{{ cert_files }}"
  notify:
     - Reload Haproxy configuration
```

</p>
</details>

```shell
molecule idempotence
```

## 7. Configuration des certificats

* configuration de HAProxy

<details><summary>tasks/main.yml</summary>
<p>

```yml
---
- name: "Copy ssl cert for web server"
  copy:
    src: "{{ item.folder }}/{{ item.filename }}"
    dest: "{{ certs_dir }}/{{ item.filename }}"
  with_items:
    - "{{ cert_files }}"
  notify:
     - Reload Haproxy configuration

- name: "intialize certs string"
  set_fact:
    certs_strings: ""

- name: "create certs string"
  set_fact:
    certs_strings: "{{ certs_strings }} crt {{ certs_dir }}/{{ item.filename }}"
  with_items:
    - "{{ cert_files }}"

- name: "view certs string"
  debug: 
    msg: "{{ certs_strings }}"

- name: "update ssl configuration"
  lineinfile:
    path: "{{ haproxy_config }}"
    regexp: '(^.*{{ frontend_port }}.*?)\ crt.*(\ no-sslv3.*$)'
    line: '\1{{ certs_strings }}\2'
    backrefs: yes
    state: present
  notify:
     - Reload Haproxy configuration
```

</p>
</details>

<details><summary>defaults/main.yml</summary>
<p>

```yml
---
haproxy_config: "/etc/haproxy/haproxy.cfg"
certs_dir: "/etc/haproxy"
frontend_port: "443"
```

</p>
</details>

```shell
molecule converge
molecule idempotence
```

## 8. Scénario de Test

* Ajout d'un scénario de test

<details><summary>molecule/default/tests/test_default.yml</summary>
<p>

```yml
# Molecule managed

---
command:
  version:
    exit-status: 0
    exec: "echo -n | openssl s_client -connect 127.0.0.1:443 -servername test2.com 2>/dev/null | openssl x509 -noout -text | grep -i 'subject:' | sed 's/^.*CN=//'"
    stdout:
    - test2.com
    stderr: []
    timeout: 1000
    skip: false
```

</p>
</details>

```shell
molecule verify
```

On valide en rejouant un test complet

```shell
molecule test
```

## 9. Ajout d'une distribution

* Ajout d'un test sur ubuntu

<details><summary>molecule.yml</summary>
<p>

```yml
---
dependency:
  name: galaxy
driver:
  name: docker
lint:
  name: yamllint
platforms:
  - name: centos
    image: centos:7
    # --- systemd ---
    command: /sbin/init
    tmpfs:
      - /run
      - /tmp
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
  - name: ubuntu
    image: ubuntu:16.04
    # --- systemd ---
    command: /sbin/init
    security_opts:
      - seccomp=unconfined  
    tmpfs:
      - /tmp
      - /run
      - /run/lock
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
provisioner:
  name: ansible
  lint:
    name: ansible-lint
verifier:
  name: goss
  lint:
    name: yamllint
```

</p>
</details>

```shell
molecule test
```

## 9. Intégration GITLAB CI

* Ajout de `.gitlab-ci.yml`

<details><summary>.gitlab-ci.yml</summary>
<p>

```yml
---
image: quay.io/ansible/molecule:latest
services:
  - docker:dind

stages:
  - tests

before_script:
  - docker -v
  - python -V
  - ansible --version
  - molecule --version

molecule:
  stage: tests
  tags:
    - docker
  variables:
    DOCKER_HOST: "tcp://docker:2375"
    PY_COLORS: 1
  script:
    - molecule test
```

## 10. driver VAGRANT

> TODO
