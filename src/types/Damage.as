package types
{
	import d2network.GameFightMinimalStats;
	
	/**
	 * ...
	 * @author Relena
	 */
	public class Damage
	{
		private var _damageNormal:Range;
		private var _damageCritical:Range;
		private var _distance:int;
		
		public function Damage(damageNormal:Range, damageCritical:Range, distance:int = 0)
		{
			_damageNormal = damageNormal;
			_damageCritical = damageCritical;
			_distance = distance;
		}
		
		public function get min():int
		{
			return _damageNormal.min;
		}
		
		public function get max():int
		{
			return _damageNormal.max;
		}
		
		public function get minCritical():int
		{
			return _damageCritical.min;
		}
		
		public function get maxCritical():int
		{
			return _damageCritical.max;
		}
		
		public function get distance():int
		{
			return _distance;
		}
	}
}