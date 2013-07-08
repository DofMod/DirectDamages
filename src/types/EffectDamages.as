package types
{
	
	/**
	 * ...
	 * @author Relena
	 */
	public class EffectDamages
	{
		public var effectId:int;
		public var damagesMin:int;
		public var damagesMax:int;
		
		public function EffectDamages(effectId:int, damagesMin:int = 0, damagesMax:int = 0)
		{
			this.effectId = effectId;
			this.damagesMin = damagesMin;
			this.damagesMax = damagesMax;
		}
		
		public function mult(factor:Number):EffectDamages
		{
			return new EffectDamages(effectId, damagesMin * factor, damagesMax * factor);
		}
		
		public function toString():String
		{
			return "[" + damagesMin + ", " + damagesMax+ "]";
		}
	}
}