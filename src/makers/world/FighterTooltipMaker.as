package makers.world
{
	import blocks.FighterBlock
	
	/**
	 * ...
	 * @author Relena
	 */
	public class FighterTooltipMaker extends Object
	{
		public function createTooltip(arg1:*, arg2:Object):Object
		{
			var tooltip:* = Api.tooltip.createTooltip("chunks/base/base.txt", "chunks/base/container.txt", "chunks/base/empty.txt");
			tooltip.addBlock(new FighterBlock().block);
			
			return tooltip;
		}
	}
}