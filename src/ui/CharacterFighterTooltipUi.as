package ui
{
	import d2api.DataApi;
	import d2api.FightApi;
	import d2api.PlayedCharacterApi;
	import d2api.SystemApi;
	import d2enums.BreedEnum;
	import d2network.ActorAlignmentInformations;
	import d2network.GameFightCharacterInformations;
	import d2network.GameFightFighterInformations;
	import flash.geom.ColorTransform;
	import managers.SpellManager;
	import ui.abstract.FighterTooltipUi;
	import utils.DamagesUtils;
	
	public class CharacterFighterTooltipUi extends FighterTooltipUi
	{
		// APIs
		public var dataApi:DataApi;
		public var playerApi:PlayedCharacterApi;
		public var systemApi:SystemApi;
		
		/**
		 *
		 * @param	fighterInfos
		 */
		protected override function updateNameLabel(fighterInfos:GameFightFighterInformations):void
		{
			var characterInfos:GameFightCharacterInformations = fighterInfos as GameFightCharacterInformations;
			
			if (fightApi.preFightIsActive())
			{
				lbl_name.text = characterInfos.name;
			}
			else if (characterInfos.stats.shieldPoints > 0)
			{
				lbl_name.text = characterInfos.name + " (" + characterInfos.stats.lifePoints;
				lbl_name.appendText("+" + characterInfos.stats.shieldPoints, "shield");
				lbl_name.appendText(")", "p");
			}
			else
			{
				lbl_name.text = characterInfos.name + " (" + characterInfos.stats.lifePoints + ")";
			}
			
			lbl_name.fullWidth();
		}
		
		/**
		 *
		 * @param	fighterInfos
		 */
		protected override function updateInfoLabel(fighterInfos:GameFightFighterInformations):void
		{
			var characterInfos:GameFightCharacterInformations = fighterInfos as GameFightCharacterInformations;
			
			if (fightApi.preFightIsActive())
			{
				var info:String;
				if (characterInfos.breed > 0)
				{
					info = dataApi.getBreed(characterInfos.breed).shortName + " " + uiApi.getText("ui.common.short.level");
				}
				else if (characterInfos.breed == BreedEnum.INCARNATION)
				{
					info = uiApi.getText("ui.common.incarnation") + " " + uiApi.getText("ui.common.short.level");
				}
				else
				{
					info += uiApi.getText("ui.common.level");
				}
				
				lbl_info.appendText(info + " " + characterInfos.level, "p");
			}
			else if (SpellManager.getInstance().getCastSpell())
			{
				displayDamages(DamagesUtils.computeDamages(SpellManager.getInstance().getCastSpell(), characterInfos, _distance), characterInfos.stats.lifePoints);
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
		protected override function updateWings(fighterInfos:GameFightFighterInformations):void
		{
			var characterInfos:GameFightCharacterInformations = fighterInfos as GameFightCharacterInformations;
			
			if (!playerApi.isInFight() || systemApi.getOption("showAlignmentWings", "dofus"))
			{
				var alignmentInfos:ActorAlignmentInformations = characterInfos.alignmentInfos;
				
				if (alignmentInfos.alignmentSide > 0 && alignmentInfos.alignmentGrade > 0)
				{
					var leftXWithPadding:int = tx_back.width / 2;
					ctr_alignment_bottom.x = leftXWithPadding;
					ctr_alignment_top.x = leftXWithPadding;
					ctr_alignment_bottom.y = tx_back.height - 4;
					
					ctr_alignment_top.addContent(tx_alignment);
					ctr_alignment_bottom.addContent(tx_alignmentBottom);
					
					var alignmentUri:* = uiApi.me().getConstant("alignment");
					if (alignmentInfos.dishonor > 0)
					{
						tx_alignment.uri = uiApi.createUri(alignmentUri + "wings.swf|fallenDemonAngel");
						tx_alignmentBottom.uri = uiApi.createUri(alignmentUri + "wings.swf|fallenDemonAngel2");
					}
					else
					{
						tx_alignment.uri = uiApi.createUri(alignmentUri + "wings.swf|demonAngel");
						tx_alignmentBottom.uri = uiApi.createUri(alignmentUri + "wings.swf|demonAngel2");
					}
					
					tx_alignment.cacheAsBitmap = true;
					tx_alignmentBottom.cacheAsBitmap = true;
					tx_alignment.gotoAndStop = (alignmentInfos.alignmentSide - 1) * 10 + 1 + alignmentInfos.alignmentGrade;
					tx_alignmentBottom.gotoAndStop = (alignmentInfos.alignmentSide - 1) * 10 + 1 + alignmentInfos.alignmentGrade;
					tx_alignment.filters = new Array();
					tx_alignmentBottom.filters = new Array();
					tx_alignment.transform.colorTransform = new ColorTransform(1, 1, 1);
					tx_alignmentBottom.transform.colorTransform = new ColorTransform(1, 1, 1);
				}
			}
		}
	}
}

