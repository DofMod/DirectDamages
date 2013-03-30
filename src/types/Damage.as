package types
{
	import d2network.GameFightMinimalStats;
	
	/**
	 * ...
	 * @author Relena
	 */
	public class Damage
	{
		private var _damage:Range;
		private var _damageCC:Range;
		private var _distance:int;
		
		public function Damage(damage:Range, damageCC:Range, distance:int = 0)
		{
			_damage = damage;
			_damageCC = damageCC;
			_distance = distance;
		}
		
		public function get min():int
		{
			return _damage.min;
		}
		
		public function get max():int 
		{
			return _damage.max;
		}
		
		public function get minCC():int 
		{
			return _damageCC.min;
		}
		
		public function get maxCC():int 
		{
			return _damageCC.max;
		}
		
		public function get distance():int
		{
			return _distance;
		}
	}
}