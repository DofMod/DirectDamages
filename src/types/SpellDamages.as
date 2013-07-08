package types
{
	import d2network.GameFightMinimalStats;
	
	/**
	 * ...
	 * @author Relena
	 */
	public class SpellDamages
	{
		public var normalDamages:Vector.<EffectDamages>;
		public var criticalDamages:Vector.<EffectDamages>;
		public var distance:int;
		public var invulnerability:Boolean;
		
		public function SpellDamages(distance:int = 0, invulnerability:Boolean = false)
		{
			this.normalDamages = new Vector.<EffectDamages>();
			this.criticalDamages = new Vector.<EffectDamages>();
			this.distance = distance;
			this.invulnerability = invulnerability;
		}
		
		public function get min():int
		{
			var sum:int = 0;
			for each (var damages:EffectDamages in normalDamages)
			{
				sum += damages.damagesMin;
			}
			
			return sum;
		}
		
		public function get max():int
		{
			var sum:int = 0;
			for each (var damages:EffectDamages in normalDamages)
			{
				sum += damages.damagesMax;
			}
			
			return sum;
		}
		
		public function get minCritical():int
		{
			var sum:int = 0;
			for each (var damages:EffectDamages in criticalDamages)
			{
				sum += damages.damagesMin;
			}
			
			return sum;
		}
		
		public function get maxCritical():int
		{
			var sum:int = 0;
			for each (var damages:EffectDamages in criticalDamages)
			{
				sum += damages.damagesMax;
			}
			
			return sum;
		}
	}
}