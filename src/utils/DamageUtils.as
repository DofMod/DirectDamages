package utils 
{
	import d2data.EffectInstance;
	import d2data.EffectsListWrapper;
	import d2data.SpellWrapper;
	import d2data.WeaponWrapper;
	import d2network.CharacterCharacteristicsInformations;
	import d2network.GameFightFighterInformations;
	import d2network.GameFightMinimalStats;
	import enum.ItemTypeIdEnum;
	import types.Damage;
	import types.Range;
	
	/**
	 * ...
	 * @author Relena
	 */
	public class DamageUtils 
	{
		public static var breedMalus:Array = new Array();
		breedMalus[ItemTypeIdEnum.BOW]     = new Array(00, 10, 10, 10, 05, 10, 10, 10, 10, 00, 10, 10, 10, 05, 10);
		breedMalus[ItemTypeIdEnum.WAND]    = new Array(00, 05, 10, 10, 10, 05, 10, 00, 10, 10, 05, 10, 10, 10, 10);
		breedMalus[ItemTypeIdEnum.STAFF]   = new Array(00, 00, 05, 10, 10, 10, 10, 05, 10, 10, 00, 10, 05, 10, 00);
		breedMalus[ItemTypeIdEnum.DAGGER]  = new Array(00, 10, 10, 10, 00, 10, 05, 10, 10, 05, 10, 10, 10, 10, 10);
		breedMalus[ItemTypeIdEnum.SWORD]   = new Array(00, 10, 10, 10, 10, 10, 00, 10, 00, 10, 10, 10, 10, 00, 10);
		breedMalus[ItemTypeIdEnum.HAMMER]  = new Array(00, 10, 00, 05, 10, 00, 10, 10, 05, 10, 10, 10, 10, 10, 10);
		breedMalus[ItemTypeIdEnum.SHOVEL]  = new Array(00, 10, 10, 00, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10);
		breedMalus[ItemTypeIdEnum.AXE]     = new Array(00, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 00, 10, 05);
		breedMalus[ItemTypeIdEnum.TOOL]    = new Array(00, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10);
		breedMalus[ItemTypeIdEnum.PICKAXE] = new Array(00, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10);
		breedMalus[ItemTypeIdEnum.SCYTHE]  = new Array(00, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10);
		//breedMalus[ItemTypeIdEnum.SOULSTONE] = new Array();
		//breedMalus[ItemTypeIdEnum.NET] = new Array();
		
		/**
		 * 
		 * @param	spell
		 * @param	targetInfos
		 * @param	distance
		 * @return
		 */
		public static function computeDamages(spell:Object, targetInfos:GameFightFighterInformations, distance:int):Damage
		{
			if (spell is SpellWrapper)
			{
				return computeDamagesSpell(spell as SpellWrapper, targetInfos, distance);
			}
			else if (spell is WeaponWrapper)
			{
				return computeDamagesWeapon(spell as WeaponWrapper, targetInfos, distance);
			}
			
			return new Damage(new Range(), new Range());
		}
		
		/**
		 * Compute initial damage (for spells).
		 * 
		 * @param	spell
		 * @param	targetInfos
		 * @param	distance
		 * @return
		 */
		private static function computeDamagesSpell(spell:SpellWrapper, targetInfos:GameFightFighterInformations, distance:int):Damage
		{
			var effect:EffectInstance;
			
			var damageLine:Range;
			var damage:Range = new Range();
			var damageCC:Range = new Range();
			
			// Simple damages
			for (var ii:int = 0; ii < spell.effects.length; ii++)
			{
				effect = spell.effects[ii];
				
				damageLine = computeInitialDamage(effect.effectId, int(effect.parameter0), int(effect.parameter1));
				
				if (distance != 1 && isSpellZone(spell.spellZoneEffects, ii))
					damageLine = applyBonus(damageLine, 1.1 - 0.1 * distance);
				
				damageLine = applyReductions(effect, damageLine, targetInfos.stats);
				
				damage.min += damageLine.min;
				damage.max += damageLine.max;
			}
			
			// Critical damages
			for (ii = 0; ii < spell.criticalEffect.length; ii++)
			{
				effect = spell.criticalEffect[ii];
				
				damageLine = computeInitialDamage(effect.effectId, int(effect.parameter0), int(effect.parameter1), true);
				
				if (distance != 1 && isSpellZone(spell.spellZoneEffects, ii))
					damageLine = applyBonus(damageLine, 1.1 - 0.1 * distance);
				
				damageLine = applyReductions(effect, damageLine, targetInfos.stats, true);
				
				damageCC.min += damageLine.min;
				damageCC.max += damageLine.max;
			}
			
			return new Damage(damage, damageCC, distance);
		}
		
		/**
		 * Compute initial damages (for weapons).
		 * 
		 * @param	weapon
		 * @param	targetInfos
		 * @param	distance
		 * @return
		 */
		private static function computeDamagesWeapon(weapon:WeaponWrapper, targetInfos:GameFightFighterInformations, distance:int):Damage
		{
			var isWeaponZone:Boolean = isWeaponZone(weapon.typeId);
			var breedMalus:int = getBreedMalus(Api.player.getPlayedCharacterInfo().breed, weapon.typeId);
			
			var effect:EffectInstance;
			
			var damageLine:Range;
			var damage:Range = new Range();
			var damageCC:Range = new Range();
			
			// Simple damages
			for each (effect in weapon.effects)
			{
				damageLine = computeInitialDamage(effect.effectId, int(effect.parameter0), int(effect.parameter1), false, 0, breedMalus);
				
				if (isWeaponZone && distance % 2 == 0)
					damageLine = applyBonus(damageLine, 1.1);
				
				damageLine = applyReductions(effect, damageLine, targetInfos.stats);
				
				damage.min += damageLine.min;
				damage.max += damageLine.max;
			}
			
			// Critical damages
			for each (effect in weapon.effects)
			{
				damageLine = computeInitialDamage(effect.effectId, int(effect.parameter0) + weapon.criticalHitBonus, effect.parameter1 ? int(effect.parameter1) + weapon.criticalHitBonus : 0, true, 0, breedMalus);
				
				if (isWeaponZone && distance % 2 == 0)
					damageLine = applyBonus(damageLine, 1.1);
				
				damageLine = applyReductions(effect, damageLine, targetInfos.stats);
				
				damageCC.min += damageLine.min;
				damageCC.max += damageLine.max;
			}
			
			return new Damage(damage, damageCC, isWeaponZone ? distance % 2 : 0);
		}
		
		/**
		 * Compute the damage of an effect.
		 * 
		 * @param	damageType	Type index of the effect.
		 * @param	damageMin	Minimal damage.
		 * @param	damageMax	Maximal damage.
		 * @param	isCriticalDamage	Is a critical hit ?
		 * @param	skillBonus	Bonus of the skill in percent.
		 * @param	breedMalus	Malus of the breed in percent.
		 * @return	The damage that whill be deal by that effect.
		 */
		private static function computeInitialDamage(damageType:int, damageMin:int, damageMax:int, isCriticalDamage:Boolean = false, skillBonus:Number = 0, breedMalus:Number = 0):Range
		{
			var characterStats:CharacterCharacteristicsInformations = Api.fight.getCurrentPlayedCharacteristicsInformations();
			var characterBreed:int = Api.player.getPlayedCharacterInfo().breed;
			
			var allDamagePercent:int = characterStats.damagesBonusPercent.objectsAndMountBonus + characterStats.damagesBonusPercent.contextModif;
			var criticalDamage:int = characterStats.criticalDamageBonus.objectsAndMountBonus + characterStats.criticalDamageBonus.contextModif;
			var allDamage:int = characterStats.allDamagesBonus.objectsAndMountBonus + characterStats.allDamagesBonus.contextModif;
			
			var damage:Range = new Range();
			
			switch (damageType) 
			{
				case 91: // water theft
				case 96: // water damages
					var chance:int = characterStats.chance.base + characterStats.chance.objectsAndMountBonus + characterStats.chance.contextModif;
					chance = chance > 0 ? chance : 0;
					
					var waterDamage:int = allDamage + characterStats.waterDamageBonus.objectsAndMountBonus + characterStats.waterDamageBonus.contextModif;
					
					damage.min =             Math.floor(Math.floor(damageMin * (1 + ((skillBonus - breedMalus) / 100))) * (1 + ((chance + allDamagePercent) / 100))) + waterDamage + (isCriticalDamage ? criticalDamage : 0);
					damage.max = damageMax ? Math.floor(Math.floor(damageMax * (1 + ((skillBonus - breedMalus) / 100))) * (1 + ((chance + allDamagePercent) / 100))) + waterDamage + (isCriticalDamage ? criticalDamage : 0) : damage.min;
					
					break;
				case 92: // earth theft
				case 97: // earth damage
					var strength:int = characterStats.strength.base + characterStats.strength.objectsAndMountBonus + characterStats.strength.contextModif;
					strength = strength > 0 ? strength : 0;
					
					var earthDamage:int = allDamage + characterStats.earthDamageBonus.objectsAndMountBonus + characterStats.earthDamageBonus.contextModif;
					
					damage.min =             Math.floor(Math.floor(damageMin * (1 + ((skillBonus - breedMalus) / 100))) * (1 + ((strength + allDamagePercent) / 100))) + earthDamage + (isCriticalDamage ? criticalDamage : 0);
					damage.max = damageMax ? Math.floor(Math.floor(damageMax * (1 + ((skillBonus - breedMalus) / 100))) * (1 + ((strength + allDamagePercent) / 100))) + earthDamage + (isCriticalDamage ? criticalDamage : 0) : damage.min;
					
					break;
				case 93: // air theft
				case 98: // air damage
					var agility:int = characterStats.agility.base + characterStats.agility.objectsAndMountBonus + characterStats.agility.contextModif;
					agility = agility > 0 ? agility : 0;
					
					var airDamage:int = allDamage + characterStats.airDamageBonus.objectsAndMountBonus + characterStats.airDamageBonus.contextModif;
					
					damage.min =             Math.floor(Math.floor(damageMin * (1 + ((skillBonus - breedMalus) / 100))) * (1 + ((agility + allDamagePercent) / 100))) + airDamage + (isCriticalDamage ? criticalDamage : 0);
					damage.max = damageMax ? Math.floor(Math.floor(damageMax * (1 + ((skillBonus - breedMalus) / 100))) * (1 + ((agility + allDamagePercent) / 100))) + airDamage + (isCriticalDamage ? criticalDamage : 0) : damage.min;
					
					break;
				case 94: // fire theft
				case 99: // fire damage
					var intelligence:int = characterStats.intelligence.base + characterStats.intelligence.objectsAndMountBonus + characterStats.intelligence.contextModif;
					agility = agility > 0 ? agility : 0;
					
					var fireDamage:int = allDamage + characterStats.fireDamageBonus.objectsAndMountBonus + characterStats.fireDamageBonus.contextModif;
					
					damage.min =             Math.floor(Math.floor(damageMin * (1 + ((skillBonus - breedMalus) / 100))) * (1 + ((intelligence + allDamagePercent) / 100))) + fireDamage + (isCriticalDamage ? criticalDamage : 0);
					damage.max = damageMax ? Math.floor(Math.floor(damageMax * (1 + ((skillBonus - breedMalus) / 100))) * (1 + ((intelligence + allDamagePercent) / 100))) + fireDamage + (isCriticalDamage ? criticalDamage : 0) : damage.min;
					
					break;
				case 95: // neutral theft (??)
				case 100: // neutral damage
					strength = characterStats.strength.base     + characterStats.strength.objectsAndMountBonus     + characterStats.strength.contextModif;
					strength = strength > 0 ? strength : 0;
					
					var neutralDamage:int = allDamage + characterStats.neutralDamageBonus.objectsAndMountBonus + characterStats.neutralDamageBonus.contextModif;
					
					damage.min =             Math.floor(Math.floor(damageMin * (1 + ((skillBonus - breedMalus) / 100))) * (1 + ((strength + allDamagePercent) / 100))) + neutralDamage + (isCriticalDamage ? criticalDamage : 0);
					damage.max = damageMax ? Math.floor(Math.floor(damageMax * (1 + ((skillBonus - breedMalus) / 100))) * (1 + ((strength + allDamagePercent) / 100))) + neutralDamage + (isCriticalDamage ? criticalDamage : 0) : damage.min;
					
					break;
			}
			
			return damage;
		}
		
		/**
		 * Get the breed malus.
		 * 
		 * @param	breedId	Index of the breed.
		 * @param	weapondTypeId	TypeId of the weapon.
		 * @return	The breed malus in percent.
		 */
		private static function getBreedMalus(breedId:int, weaponTypeId:int):Number
		{
			if (breedMalus[weaponTypeId] === undefined || breedMalus[weaponTypeId][breedId] === undefined)
			{
				return 0;
			}
			
			return breedMalus[weaponTypeId][breedId];
		}
		
		/**
		 * Test if the spell do zone damages.
		 * 
		 * @param	spellZoneEffects	Effect of the spell.
		 * @param	Index	Index of the effect.
		 * @return	True if the spell do zone damages.
		 */
		private static function isSpellZone(spellZoneEffects:Object, index:int):Boolean
		{
			var zone:Object = (index < spellZoneEffects.length) ? spellZoneEffects[index] : spellZoneEffects[0];
			
			// 80 = Point
			if (zone.zoneShape == 80)
				return false;
				
			return true;
		}
		
		/**
		 * Test if the weapon is a hammer or a staff.
		 * 
		 * @param	weaponTypeId	TypeId of the weapon.
		 * @return	True if the weapon is a hammer or a staff.
		 */
		private static function isWeaponZone(weaponTypeId:int):Boolean
		{
			if (weaponTypeId == ItemTypeIdEnum.HAMMER || weaponTypeId == ItemTypeIdEnum.STAFF)
				return true;
				
			return false;
		}
		
		/**
		 * Apply a bonus (or a malus) to the damages.
		 * 
		 * @param	damage
		 * @param	bonusCoeff
		 * @return
		 */
		private static function applyBonus(damage:Range, bonusCoeff:Number):Range
		{
			return damage.applyCoeff(bonusCoeff);
		}
		
		/**
		 * Apply reductions --- DommagesSubis = ( 1 - Résistance% / 100 ) * ( Dommages - Résistance )
		 * 
		 * @param	effect
		 * @param	damages
		 * @param	targetStats
		 * @param	isCriticalDamage
		 * @return
		 */
		private static function applyReductions(effect:Object, damage:Range, targetStats:GameFightMinimalStats, isCriticalDamage:Boolean = false):Range
		{
			switch (effect.effectId) 
			{
				case 91: // water theft
				case 96: // water damages
					damage.min = (1 - targetStats.waterElementResistPercent / 100) * (damage.min - targetStats.waterElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					damage.max = (1 - targetStats.waterElementResistPercent / 100) * (damage.max - targetStats.waterElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case 92: // earth theft
				case 97: // earth damage
					damage.min = (1 - targetStats.earthElementResistPercent / 100) * (damage.min - targetStats.earthElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					damage.max = (1 - targetStats.earthElementResistPercent / 100) * (damage.max - targetStats.earthElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case 93: // air theft
				case 98: // air damage
					damage.min = (1 - targetStats.airElementResistPercent / 100) * (damage.min - targetStats.airElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					damage.max = (1 - targetStats.airElementResistPercent / 100) * (damage.max - targetStats.airElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case 94: // fire theft
				case 99: // fire damage
					damage.min = (1 - targetStats.fireElementResistPercent / 100) * (damage.min - targetStats.fireElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					damage.max = (1 - targetStats.fireElementResistPercent / 100) * (damage.max - targetStats.fireElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case 95: // neutral theft (??)
				case 100: // neutral damage
					damage.min = (1 - targetStats.neutralElementResistPercent / 100) * (damage.min - targetStats.neutralElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					damage.max = (1 - targetStats.neutralElementResistPercent / 100) * (damage.max - targetStats.neutralElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				default:
			}
			
			return damage;
		}
		
		/**
		 * Scan all buffs and try to deal with them.
		 * 
		 * @param	damage
		 * @param	target
		 * @return
		 */
		private static function applyBuffReduction(damage:Range, target:GameFightFighterInformations):Range
		{
			var buffList:EffectsListWrapper = Api.fight.getAllBuffEffects(target.contextualId);
			
			for each (var category:Object in buffList.categories) 
			{
				for each (var buff:Object in buffList.buffArray[category]) 
				{
					var effect:EffectInstance = buff.effects;
					
					Api.system.log(2, "effect (" + effect.effectId + "): " + effect.description);
					
					switch (effect.effectId) 
					{
						case 265: // Earth armour
							return applyElementalArmour(buff, damage, target);
							
							break;
					}
				}
			}
			
			return damage;
		}
		
		/**
		 * 
		 * @param	buff
		 * @param	damage
		 * @param	target
		 * @return
		 */
		private static function applyElementalArmour(buff:Object, damage:Range, target:GameFightFighterInformations):Range
		{
			var level:int = Api.fight.getFighterLevel(target.contextualId);
			
			// Reduction * (100 + 5 * level) / 100
			
			return damage;
		}
	}
}