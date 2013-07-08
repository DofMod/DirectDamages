DirectDamages
=============

By *Relena*

Ce module calcul les dégâts infligés par un sort sur la cible.

Le résultat est ensuite affiché ma façon concise sur une seule ligne dans l'infobulle sous le pseudo de la cible. Cette ligne se compose de 4 nombres maximums selon le schéma suivant : 

    [Dégâts minimums] à [Dégâts maximums] ([Dégâts minimums en CC] à [Dégâts maximums en CC])

Pour faire ce calcul, le module prend en compte:
* Les dégâts de base du sort (en fonction du niveau de celui-ci).
* Les différents type de dommages : neutre, air, terre, feu, eau, poussé.
* Les statistiques du personnage (dommage fixe, %dommage, ...).
* Les boosts du personnage (maîtrise d'arme, +dommage fixe, ...).
* Les résistances de la cible (résistance fixe, %résistance, ...).
* Le type de cible (dégâts plus important sur les invocations, ...).
* Les CàC et sorts de zone (75% pour les CàC, 90% à 60% pour les sorts).
* Les immunités.

Ne sont pas encore pris en compte:
* Les dégâts de type : %érosion, poison, piège, ...
* Les boucliers Zobals.
* Les armures (Armure aqueuse, Mot de prévention, ...).
* Les renvois de sorts.

![Différents affichages des dégâts du sort 'épée de iop' en fonction de la vitalité de la cible](http://imageshack.us/a/img194/220/hyk0hik.png "Différents affichages des dégâts du sort 'épée de iop' en fonction de la vitalité de la cible")

![Royalmouth invulnérable](http://imageshack.us/a/img703/4894/invulnerm.png "Royalmouth invulnérable")

Une vidéo de présentation du module est visualisable sur la chaine Youtube [DofusModules](https://www.youtube.com/user/dofusModules "Youtube, DofusModules"):

[Lien vers la vidéo](https://www.youtube.com/watch?v=r6u7f9htF44 "Vidéo de présentation du module")

Download + Compile:
-------------------

1. Install Git
2. git clone --recursive https://github.com/Dofus/DirectDamages.git
3. cd DirectDamages/dmUtils
4. compile dmUtils library (see README)
5. cd ..
6. mxmlc -output DirectDamages.swf -compiler.library-path+=./modules-library.swc -compiler.library-path+=./dmUtils/dmUtils.swc -source-path src -keep-as3-metadata Api Module DevMode -- src/DirectDamages.as

Installation:
=============

1. Create a new *DirectDamages* folder in the *ui* folder present in your Dofus instalation folder. (i.e. *ui/DirectDamages*)
2. Copy the following files in this new folder:
    * xml/
    * chunks/
    * DirectDamages.swf
    * Relena_DirectDamages.dm
3. Launch Dofus
4. Enable the module in your config menu.
5. ...
6. Profit!
