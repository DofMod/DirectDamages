package enum
{
	
	/**
	 * ...
	 *
	 * @author Relena
	 */
	public class TargetMaskEnum
	{
		public static const CASTER:String = "c";
		public static const CASTER_INCLUDED:String = "C";
		public static const STATIC_INVOCATION:String = "s";
		public static const STATIC_INVOCATION_ENEMY:String = "S";
		public static const INVOCATION:String = "i";
		public static const INVOCATION_ENEMY:String = "I";
		public static const PLAYER:String = "h";
		public static const PLAYER_ENEMY:String = "H";
		public static const MONSTER:String = "m";
		public static const MONSTER_ENEMY:String = "M";
		public static const ALL:String = "a"; // c, h, i, m, s
		public static const ALL_ENEMY:String = "A"; // H, I, M, S
	}
}