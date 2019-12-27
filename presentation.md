---
marp: true
theme: simple
paginate: true
auto-scaling: true
---

<style>
img[alt~="center"] {
  display: block;
  margin: 0 auto;
}
img {
  background: transparent
}
section {
  background: #fff url(images/background.jpg) no-repeat center center;
  background-size: cover;
}
h1 {
      font-size: 60px;
}

</style>

![width:400px center](images/molecule.png)

---

## Généralités

* Version 2 majeure en 2017
* Version mineure tous les 2 mois
* Module écrit en python
* Appartient au projet Ansible
* S'appuie sur les normes ansible-galaxy

---

<style scoped>
{
  text-align: center;
}
</style>

# URL

<https://github.com/ansible/molecule>
<https://molecule.readthedocs.io>

---

<style scoped>
{
  text-align: center;
}
</style>

# Installation
*"why not do it with some style?"*

---

```bash
# Python
sudo apt install -y python
sudo apt install -y python-pip libssl-dev

# Ansible
pip install ansible

# Molecule
pip install molecule
molecule –version
```

---

![bg cover](images/background.jpg)

## Pré-requis

### Driver Docker

* Runtime docker
* Module docker-py

### Driver VAGRANT

* Vagrant
* VirtualBox
* Module python-vagrant

---

<style scoped>
{
  text-align: center;
}
</style>

# Les bases

*"Wait ... what the hell is a gigawatt?!"*

---

<style scoped>
{
  text-align: center;
}
</style>

# Idempotence

une opération qui abouti au ***même résultat*** qu'on l'applique une ou ***plusieurs fois***.

---

## <!-- center --> Structure Ansible-galaxy

```ini
[README.md]
  Fichier principal de documentation
[defaults/]
  Variables avec valeurs par défaut (surchargeable)
[vars/]
  Variables qui représentent les paramètres d'appel
[files/]
  Fichiers libres
[handlers/]
  Handlers déclenchés en fin d'exécution par notification
[meta/]
  Informations meta pour le hub ansible-galaxy
[tasks/]
  Ensemble de tâches
[templates/]
  Templates JINJA
[tests/]
  Scripts de test *... on va y venir!!!*
```

---

<style scoped>
{
  text-align: center;
}
</style>

# Fonctionnement

*"You're not thinking fourth dimensionally!"*

---

![bg cover](images/doc.jpg)

<style scoped>
h1 {
  color: white

}
{
  color: white
}
</style>

# Exercices
If you put your mind to it,
you can accomplish anything !

---

<style scoped>
section {
  background: #fff
}
</style>

![bg left:40%](images/caffeine.jpg)

<style scoped>
h1 {
  color: black;
}
</style>

# Merci à tous
((( Une seule molécule compte )))
