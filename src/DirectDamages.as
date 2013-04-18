package
{
	import d2api.ConfigApi;
	import d2api.DataApi;
	import d2api.FightApi;
	import d2api.PlayedCharacterApi;
	import d2api.SystemApi;
	import d2api.TooltipApi;
	import d2api.UiApi;
	import d2hooks.CancelCastSpell;
	import d2hooks.CastSpellMode;
	import flash.display.Sprite;
	import makers.world.FighterTooltipMaker;
	import managers.SpellManager;
	import ui.CharacterFighterTooltipUi;
	import ui.MonsterFighterTooltipUi;
	
	/**
	 * Main function of the Noob module.
	 *
	 * @author Relena
	 */
	public class DirectDamages extends Sprite
	{
		//::////////////////////////////////////////////////////////////////////
		//::// Properties
		//::////////////////////////////////////////////////////////////////////
		
		// Includes
		private var includeUi:Array = [];
		
		// APIs
		public var configApi:ConfigApi;
		public var dataApi:DataApi;
		public var playerApi:PlayedCharacterApi;
		public var fightApi:FightApi;
		public var sysApi:SystemApi;
		public var tooltipApi:TooltipApi;
		public var uiApi:UiApi;
		
		//::////////////////////////////////////////////////////////////////////
		//::// Methods
		//::////////////////////////////////////////////////////////////////////
		
		/**
		 * @private
		 * 
		 * Initialize the module.
		 */
		public function main():void
		{
			initApis();
			
			sysApi.addHook(CastSpellMode, onCastSpellMode);
			sysApi.addHook(CancelCastSpell, onCancelCastSpell);
			
			tooltipApi.registerTooltipMaker("monsterFighter", FighterTooltipMaker, MonsterFighterTooltipUi);
			tooltipApi.registerTooltipMaker("playerFighter", FighterTooltipMaker, CharacterFighterTooltipUi);
		}
		
		/**
		 * Initialize the Api class.
		 */
		private function initApis():void
		{
			Api.config = configApi;
			Api.data = dataApi;
			Api.fight = fightApi;
			Api.player = playerApi;
			Api.system = sysApi;
			Api.tooltip = tooltipApi;
			Api.ui = uiApi;
		}
		
		/**
		 * @private
		 * 
		 * Cleanup function.
		 */
		public function unload():void
		{
		}
		
		//::////////////////////////////////////////////////////////////////////
		//::// Events
		//::////////////////////////////////////////////////////////////////////
		
		/**
		 * 
		 * @param	spell
		 */
		public function onCastSpellMode(spell:Object):void
		{
			SpellManager.getInstance().setCastSpell(spell);
		}
		
		/**
		 * 
		 * @param	spell
		 */
		public function  onCancelCastSpell(spell:Object):void 
		{
			SpellManager.getInstance().cancelCastSpell();
		}
	}
}
