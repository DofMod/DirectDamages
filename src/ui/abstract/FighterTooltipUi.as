package ui.abstract
{
	import d2api.FightApi;
	import d2api.SystemApi;
	import d2api.TooltipApi;
	import d2api.UiApi;
	import d2components.GraphicContainer;
	import d2components.Label;
	import d2components.Texture;
	import d2enums.FightEventEnum;
	import d2hooks.CancelCastSpell;
	import d2hooks.CastSpellMode;
	import d2hooks.FightEvent;
	import d2network.GameFightFighterInformations;
	import flash.display.Sprite;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import managers.SpellManager;
	import types.SpellDamages;
	import utils.DamagesUtils;
	
	/**
	 * Abstract tooltip ui class.
	 *
	 * @author Relena
	 */
	public class FighterTooltipUi extends Sprite
	{
		// APIs
		public var sysApi:SystemApi;
		public var tooltipApi:TooltipApi;
		public var uiApi:UiApi;
		public var fightApi:FightApi;
		
		// Components
		public var mainCtr:Object;
		public var ctr_alignment_top:GraphicContainer;
		public var ctr_alignment_bottom:GraphicContainer;
		public var infosCtr:GraphicContainer;
		public var tx_back:GraphicContainer;
		public var tx_alignment:Texture;
		public var tx_alignmentBottom:Texture;
		public var lbl_name:Label;
		public var lbl_info:Label;
		
		//Others
		private var _timerHide:Timer;
		private var _tooltipParam:Object;
		protected var _distance:int;
		
		// Abstract functions
		protected function updateNameLabel(fighterInfos:GameFightFighterInformations):void { };
		protected function updateInfoLabel(fighterInfos:GameFightFighterInformations):void { };
		protected function updateWings(fighterInfos:GameFightFighterInformations):void { };
		
		/**
		 * Main ui function, create hooks and update the tooltip content.
		 * 
		 * @param	params
		 */
		public function main(params:Object = null):void
		{
			DamagesUtils.init(sysApi, fightApi);
			
			_tooltipParam = params;
			_distance = 0;
			
			sysApi.addHook(CastSpellMode, onCastSpellMode);
			sysApi.addHook(CancelCastSpell, onCancelCastSpell);
			sysApi.addHook(FightEvent, onFightEvent);
			
			updateContent(params);
			
			if (params.autoHide)
			{
				_timerHide = new flash.utils.Timer(2500);
				_timerHide.addEventListener(flash.events.TimerEvent.TIMER, onTimer);
				_timerHide.start();
			}
		}
		
		/**
		 * Fill the labels, update the size and place the tooltip.
		 * 
		 * @param	params
		 */
		public function updateContent(params:Object = null):void
		{
			if (params == null)
				params = _tooltipParam;
			
			var fighterInfos:GameFightFighterInformations = params.data;
			
			lbl_name.text = "";
			lbl_info.text = "";
			
			updateNameLabel(fighterInfos);
			updateInfoLabel(fighterInfos);
			
			// update background
			tx_back.removeFromParent();
			
			if (lbl_info.text != "")
			{
				lbl_info.x = (lbl_name.width - lbl_info.width) / 2;
				lbl_info.y = 20;
				
				if (lbl_info.width > lbl_name.width)
				{
					tx_back.x = lbl_info.x - 4;
					tx_back.width = lbl_info.width + 8;
				}
				else
				{
					tx_back.x = lbl_name.x - 4;
					tx_back.width = lbl_name.width + 8;					
				}
				
				tx_back.height = infosCtr.height + 8;
			}
			else
			{
				tx_back.x = lbl_name.x - 4;
				tx_back.width = lbl_name.width + 8;				
				tx_back.height = infosCtr.height + 8;
			}
			
			infosCtr.addContent(tx_back, 0);
			
			// remove wings
			tx_alignment.removeFromParent();
			tx_alignmentBottom.removeFromParent();
			
			// place tooltip without wings
			uiApi.me().x = 0;
			uiApi.me().y = 0;
			tooltipApi.place(params.position, params.point, params.relativePoint, params.offset);
			
			// update wings
			updateWings(fighterInfos);
		}
		
		/**
		 * Format and display the damages in the lbl_info label.
		 *
		 * @param	damage
		 * @param	monsterLife
		 */
		protected function displayDamages(damages:SpellDamages, monsterLife:int):void
		{
			if (damages == null)
				return;
			
			if (damages.invulnerability)
			{
				lbl_info.appendText("Invulnérable", "etheral");
				
				return;
			}
			
			if (damages.distance > 0)
				lbl_info.appendText(damages.distance + ": ", "itemset");
			
			if (damages.min != damages.max && (monsterLife - damages.min) > 0)
			{
				lbl_info.appendText(damages.min.toString(), "p");
				lbl_info.appendText(" à ", "p");
			}
			
			lbl_info.appendText(((monsterLife - damages.max) > 0) ? damages.max.toString() : "mort", "shield");
			lbl_info.appendText(" (", "p");
			
			if (damages.minCritical != damages.maxCritical && (monsterLife - damages.minCritical) > 0)
			{
				lbl_info.appendText(damages.minCritical.toString(), "p");
				lbl_info.appendText(" à ", "p");
			}
			
			lbl_info.appendText(((monsterLife - damages.maxCritical) > 0) ? damages.maxCritical.toString() : "mort", "etheral");
			lbl_info.appendText(")", "p");
		}
		
		/**
		 * Cleanup function.
		 */
		public function unload():void
		{
			sysApi.removeHook(CastSpellMode);
			sysApi.removeHook(CancelCastSpell);
			sysApi.removeHook(FightEvent);
			
			if (_timerHide)
			{
				_timerHide.removeEventListener(TimerEvent.TIMER, onTimer);
				_timerHide.stop();
				_timerHide = null;
			}
		}
		
		//::////////////////////////////////////////////////////////////////////
		//::// Events
		//::////////////////////////////////////////////////////////////////////
		
		/**
		 * This callback isprocess when the TimerEvent.TIMER hook is raised.
		 * Hide the tooltip.
		 *
		 * @param	timer
		 */
		private function onTimer(timer:TimerEvent):void
		{
			_timerHide.removeEventListener(TimerEvent.TIMER, onTimer);
			
			uiApi.hideTooltip(uiApi.me().name);
		}
		
		/**
		 * This callback is process when the CastSpellMode hook is raided.
		 * Increment the distance variable then update the tooltip.
		 *
		 * @param	spell
		 */
		private function onCastSpellMode(spell:Object):void
		{
			var prevousSpell:Object = SpellManager.getInstance().getPreviousCastSpell();
			
			if (spell == prevousSpell)
				_distance += 1;
			else
				_distance = 0;
			
			updateContent();
		}
		
		/**
		 * This callback is process when the CancelCastSpell hook is raised.
		 * Just update the tooltip.
		 *
		 * @param	spell
		 */
		private function onCancelCastSpell(spell:Object):void
		{
			updateContent();
		}
		
		/**
		 * This callback is process when the FightEvent hook is raised. Track
		 * the spell's infos and display them if the right ui is loaded.
		 *
		 * @param	eventName	Name of the current event.
		 * @param	params		Parameters of the current event.
		 * @param	targetList	(not used).
		 */
		private function onFightEvent(eventName:String, params:Object, targetList:Object = null):void
		{
			if (eventName == FightEventEnum.FIGHTER_CASTED_SPELL)
			{
				updateContent();
			}
		}
	}
}