package managers 
{
	import errors.SingletonError;
	
	/**
	 * ...
	 * @author Relena
	 */
	public class SpellManager 
	{		 	
		// Statics
		private static var _instance:SpellManager = null;
		private static var _allowInstance:Boolean = false;
		
		// Others
		private var _previousSpell:Object = null;
		private var _castingSpell:Object = null;
		
		public static function getInstance():SpellManager
		{
			if (!_instance)
			{
				_allowInstance = true;
				_instance = new SpellManager();
				_allowInstance = false;
			}

			return _instance;
		}
		
		public function SpellManager()
		{
			if (!_allowInstance)
				throw new SingletonError();
		}
		
		public function setCastSpell(spell:Object):void
		{
			_castingSpell = spell;
		}
		
		public function cancelCastSpell():void 
		{
			_previousSpell = _castingSpell;
			_castingSpell = null;
		}
		
		public function getCastSpell():Object
		{
			return _castingSpell;
		}
		
		public function getPreviousCastSpell():Object
		{
			return _previousSpell;
		}
	}
}