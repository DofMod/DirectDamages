package blocks
{
	/**
	 * ...
	 * @author Relena
	 */
	public class FighterBlock extends Object
	{
		private var _content:String;
		private var _block:Object;
		
		public function FighterBlock()
		{
			this._block = Api.tooltip.createTooltipBlock(this.onAllChunkLoaded, this.getContent);
			this._block.initChunk([Api.tooltip.createChunkData("content", "chunks/world/fighterFight.txt")]);
		}
		
		public function onAllChunkLoaded():void
		{
			this._content = this._block.getChunk("content").processContent({});
		}
		
		public function getContent():String
		{
			return this._content;
		}
		
		public function get block():Object
		{
			return this._block;
		}
	}
}