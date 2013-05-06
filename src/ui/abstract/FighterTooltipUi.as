package ui.abstract
{
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
	import types.Damage;
	
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
				// Center lbl_info
				var centerX:int = (lbl_info.width - lbl_name.width) / 2;
				if (centerX < 0)
				{
					lbl_info.y = 20;
					lbl_info.x = -centerX;
				}
				else
				{
					lbl_info.x = 0;
					lbl_info.y = 20;
					lbl_name.x = centerX;
				}
				
				var leftXWithPadding:int = lbl_name.x + lbl_name.width + 8;
				if (leftXWithPadding < lbl_info.width + 8)
				{
					tx_back.width = lbl_info.width + 8;
				}
				else
				{
					tx_back.width = leftXWithPadding;
				}
				
				tx_back.height = infosCtr.height + 8;
			}
			else
			{
				if (lbl_name.width < 60)
				{
					lbl_name.x = (60 - lbl_name.width) / 2;
					tx_back.width = 68;
				}
				else
				{
					tx_back.width = lbl_name.width + 8;
				}
				
				tx_back.height = infosCtr.height + 5;
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
		protected function displayDamage(damage:Damage, monsterLife:int):void
		{
			if (damage.min == 0 && damage.max == 0 && damage.minCritical == 0 && damage.maxCritical == 0)
				return;
			
			if (damage.isInvulnerable())
			{
				lbl_info.appendText("Invulnérable", "etheral");
				
				return;
			}
			
			if (damage.distance > 0)
				lbl_info.appendText(damage.distance + ": ", "itemset");
			
			if (damage.min != damage.max && (monsterLife - damage.min) > 0)
			{
				lbl_info.appendText(damage.min.toString(), "p");
				lbl_info.appendText(" à ", "p");
			}
			
			lbl_info.appendText(((monsterLife - damage.max) > 0) ? damage.max.toString() : "mort", "shield");
			lbl_info.appendText(" (", "p");
			
			if (damage.minCritical != damage.maxCritical && (monsterLife - damage.minCritical) > 0)
			{
				lbl_info.appendText(damage.minCritical.toString(), "p");
				lbl_info.appendText(" à ", "p");
			}
			
			lbl_info.appendText(((monsterLife - damage.maxCritical) > 0) ? damage.maxCritical.toString() : "mort", "etheral");
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