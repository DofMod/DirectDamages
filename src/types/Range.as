package types
{
	
	/**
	 * ...
	 * @author Relena
	 */
	public class Range
	{
		public var min:int;
		public var max:int;
		
		public function Range()
		{
			min = max = 0;
		}
		
		public function applyCoeff(coeff:Number):Range
		{
			min *= coeff;
			max *= coeff;
			
			return this;
		}
		
		public function toString():String
		{
			return "[" + min + ", " + max + "]";
		}
	}
}