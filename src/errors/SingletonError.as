package errors 
{
	/**
	 * Singleton error class.
	 * 
	 * @author Relena
	 */
	public class SingletonError extends Error 
	{
		private const _errorMsg:String = "Can't create an instance of a singleton class."
		
		public function toString():String
		{
			return _errorMsg;
		}
	}
}