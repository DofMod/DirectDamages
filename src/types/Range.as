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
		
		public function Range(min:int = 0, max:int = 0)
		{
			this.min = min;
			this.max = max;
		}
		
		public function mult(factor:Number):Range
		{
			return new Range(min * factor, max * factor);
		}
		
		public function toString():String
		{
			return "[" + min + ", " + max + "]";
		}
	}
}