package ui
{
	import d2api.DataApi;
	import d2api.FightApi;
	import d2data.Monster;
	import d2network.GameFightFighterInformations;
	import d2network.GameFightMonsterInformations;
	import managers.SpellManager;
	import ui.abstract.FighterTooltipUi;
	import utils.DamageUtils;
	
	public class MonsterFighterTooltipUi extends FighterTooltipUi
	{
		// APIs
		public var dataApi:DataApi;
		public var fightApi:FightApi;
		
		/**
		 *
		 * @param	fighterInfos
		 */
		protected override function updateInfoLabel(fighterInfos:GameFightFighterInformations):void
		{
			var monsterInfos:GameFightMonsterInformations = fighterInfos as GameFightMonsterInformations;
			
			if (fightApi.preFightIsActive())
			{
				var levelFormated:String = "";
				
				var monsterId:int = fightApi.getMonsterId(monsterInfos.contextualId);
				if (monsterId > -1)
				{
					var monster:Monster = dataApi.getMonsterFromId(monsterId);
					if (monster.isBoss) // Gardiens de donjons
					{
						levelFormated = uiApi.getText("ui.item.boss") + " " + uiApi.getText("ui.common.short.level"); // + "Niv.";
					}
					else if (monster.isMiniBoss) // Archi-monstres
					{
						levelFormated = uiApi.getText("ui.item.miniboss") + " " + uiApi.getText("ui.common.short.level"); // + "Niv.";
					}
				}
				
				if (levelFormated == "")
				{
					levelFormated = uiApi.getText("ui.common.level"); // + "Niveau"
				}
				
				lbl_info.appendText(levelFormated + " " + fightApi.getFighterLevel(monsterInfos.contextualId), "p");
			}
			else if (SpellManager.getInstance().getCastSpell())
			{
				displayDamage(DamageUtils.computeDamages(SpellManager.getInstance().getCastSpell(), monsterInfos, _distance), monsterInfos.stats.lifePoints);
			}
			else
			{
				lbl_info.fullWidth();
				lbl_info.removeFromParent();
				return;
			}
			
			lbl_info.useCustomFormat = true;
			lbl_info.fullWidth();
			infosCtr.addContent(lbl_info);
		}
		
		/**
		 *
		 * @param	fighterInfos
		 */
		protected override function updateNameLabel(fighterInfos:GameFightFighterInformations):void
		{
			var monsterInfos:GameFightMonsterInformations = fighterInfos as GameFightMonsterInformations;
			
			if (fightApi.preFightIsActive())
			{
				lbl_name.text = fightApi.getFighterName(monsterInfos.contextualId);
			}
			else if (monsterInfos.stats.shieldPoints > 0)
			{
				lbl_name.text = fightApi.getFighterName(monsterInfos.contextualId) + " (" + monsterInfos.stats.lifePoints;
				lbl_name.appendText("+" + monsterInfos.stats.shieldPoints, "shield");
				lbl_name.appendText(")", "p");
			}
			else
			{
				lbl_name.text = fightApi.getFighterName(monsterInfos.contextualId) + " (" + monsterInfos.stats.lifePoints + ")";
			}
			
			lbl_name.fullWidth();
		}
	}
}