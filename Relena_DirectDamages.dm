<?xml version="1.0" ?><module>

	<!-- Information sur le module -->
	<header>
		<!-- Nom affiché dans la liste des modules -->
		<name>DirectDamages</name>
		<!-- Version du module -->
		<version>0.387</version>
		<!-- Dernière version de dofus pour laquelle ce module fonctionne -->
		<dofusVersion>2.11.0</dofusVersion>
		<!-- Auteur du module -->
		<author>Relena</author>
		<!-- Courte description -->
		<shortDescription>Prédiction des dégâts en combat.</shortDescription>
		<!-- Description détaillée -->
		<description>Ce module calcul les dégâts (min et max) qui seront occasionné à la cible. Ces dégâts sont affichés dans l'infobulle, en dessous du pseudo de la cible survolé. Ce calcul prend en compte les dégâts de base du sort sélectionné, les caractéristiques de l'attaquant et de la cible.</description>
	</header>

	<!-- Liste des interfaces du module, avec nom de l'interface, nom du fichier squelette .xml et nom de la classe script d'interface -->
	<uis>
		<!-- <ui class="ui::SpellsTrackerConfig" file="xml/SpellsTrackerConfig.xml" name="SpellsTrackerConfig"/> -->
	</uis>
	
	<script>DirectDamages.swf</script>
</module>