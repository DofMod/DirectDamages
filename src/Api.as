package
{
	import d2api.ConfigApi;
	import d2api.DataApi;
	import d2api.FightApi;
	import d2api.PlayedCharacterApi;
	import d2api.SystemApi;
	import d2api.TooltipApi;
	import d2api.UiApi;
	
	/**
	 * APIs globals
	 *
	 * @author Relena
	 */
	public class Api
	{
		public static var config:ConfigApi;
		public static var data:DataApi;
		public static var fight:FightApi;
		public static var player:PlayedCharacterApi;
		public static var system:SystemApi;
		public static var tooltip:TooltipApi;
		public static var ui:UiApi;
	}
}