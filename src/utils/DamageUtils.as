package utils 
{
	import d2data.EffectInstance;
	import d2data.EffectsListWrapper;
	import d2data.SpellWrapper;
	import d2data.WeaponWrapper;
	import d2network.CharacterCharacteristicsInformations;
	import d2network.GameFightFighterInformations;
	import d2network.GameFightMinimalStats;
	import enums.BuffEffectCategoryEnum;
	import enums.EffectIdEnum;
	import enums.ItemTypeIdEnum;
	import enums.TargetMaskEnum;
	import types.SpellDamages;
	import types.EffectDamages;
	
	/**
	 * ...
	 * @author Relena
	 */
	public class DamageUtils 
	{
		/**
		 * 
		 * @param	spell		Spell informations (SpellWrapper or WeaponWrapper).
		 * @param	targetInfos	Target informations (characteristics, ...).
		 * @param	distance	Distance between the targeted point and the target.
		 * @return	A Damage object and Null if error.
		 */
		public static function computeDamages(spell:Object, targetInfos:GameFightFighterInformations, distance:int = 0):SpellDamages
		{
			if (isInvulnerable(targetInfos.contextualId))
			{
				return new SpellDamages(0, true);
			}
			if (spell is SpellWrapper)
			{
				return computeDamagesSpell(spell as SpellWrapper, targetInfos, distance % 5);
			}
			else if (spell is WeaponWrapper)
			{
				return computeDamagesWeapon(spell as WeaponWrapper, targetInfos, distance % 2);
			}
			
			return null;
		}
		
		/**
		 * Compute initial damage (for spells).
		 * 
		 * @param	spell		Spell informations.
		 * @param	targetInfos	Target informations (characteristics, ...).
		 * @param	distance	Distance between the targeted point and the target.
		 * @return	A Damage object and Null if error.
		 */
		private static function computeDamagesSpell(spell:SpellWrapper, targetInfos:GameFightFighterInformations, distance:int):SpellDamages
		{
			var characterStats:CharacterCharacteristicsInformations = Api.fight.getCurrentPlayedCharacteristicsInformations();
			
			var targeterTeam:String = Api.fight.getFighterInformations(targetInfos.contextualId).team;
			var targetTeam:String = Api.fight.getFighterInformations(Api.fight.getCurrentPlayedFighterId()).team;
			
			var isTargetMe:Boolean = (targetInfos.contextualId == Api.fight.getCurrentPlayedFighterId());
			var isTargetInMyTeam:Boolean = (targeterTeam == targetTeam);
			var isTargetAnInvocation:Boolean = targetInfos.stats.summoned;
			
			var effect:EffectInstance = null;
			
			var spellDamages:SpellDamages = new SpellDamages(distance);
			var effectDamages:EffectDamages = null;
			
			var doDamage:Boolean = false;
			
			// Simple damages
			for (var ii:int = 0; ii < spell.effects.length; ii++)
			{
				effect = spell.effects[ii];
				
				if (!isTargetAffected(effect.targetMask, isTargetInMyTeam, isTargetAnInvocation, isTargetMe))
					continue;
				
				effectDamages = computeInitialDamage(effect, characterStats);
				if (effectDamages  == null)
					continue;
				
				if (distance != 0 && isSpellZone(spell.spellZoneEffects, ii))
					effectDamages = applyBonus(effectDamages , 1.0 - 0.1 * distance);
				
				effectDamages = applyReductions(effect, effectDamages, targetInfos.stats);
				
				spellDamages.normalDamages.push(effectDamages);
			}
			
			// Critical damages
			for (ii = 0; ii < spell.criticalEffect.length; ii++)
			{
				effect = spell.criticalEffect[ii];
				
				if (!isTargetAffected(effect.targetMask, isTargetInMyTeam, isTargetAnInvocation, isTargetMe))
					continue;
				
				effectDamages = computeInitialDamage(effect, characterStats, true);
				if (effectDamages == null)
					continue;
				
				if (distance != 0 && isSpellZone(spell.spellZoneEffects, ii))
					effectDamages = applyBonus(effectDamages, 1.0 - 0.1 * distance);
				
				effectDamages = applyReductions(effect, effectDamages, targetInfos.stats, true);
				
				spellDamages.criticalDamages.push(effectDamages);
			}
			
			if (spellDamages.normalDamages.length == 0 && spellDamages.criticalDamages.length == 0)
				return null;
			
			return spellDamages;
		}
		
		/**
		 * Compute initial damages (for weapons).
		 * 
		 * @param	weapon		Weapon informations.
		 * @param	targetInfos	Target informations (characteristics, ...).
		 * @param	distance	Distance between the targeted point and the target.
		 * @return	A Damage object and Null if error.
		 */
		private static function computeDamagesWeapon(weapon:WeaponWrapper, targetInfos:GameFightFighterInformations, distance:int):SpellDamages
		{
			var isWeaponZone:Boolean = isWeaponZone(weapon.typeId);
			var characterStats:CharacterCharacteristicsInformations = Api.fight.getCurrentPlayedCharacteristicsInformations();
			var skillBonus:int = getSkillBonus();
			
			var effect:EffectInstance;
			
			var spellDamages:SpellDamages = new SpellDamages(isWeaponZone ? distance : 0);
			var effectDamages:EffectDamages = null;
			
			// Simple damages
			for each (effect in weapon.effects)
			{
				effectDamages = computeInitialDamage(effect, characterStats, false, 0, skillBonus);
				if (effectDamages == null)
					continue;
				
				if (isWeaponZone && distance % 2 == 1)
					effectDamages = applyBonus(effectDamages, 0.75);
				
				effectDamages = applyReductions(effect, effectDamages, targetInfos.stats);
				
				spellDamages.normalDamages.push(effectDamages);
			}
			
			// Critical damages
			for each (effect in weapon.effects)
			{
				effectDamages = computeInitialDamage(effect, characterStats, true, weapon.criticalHitBonus, skillBonus);
				if (effectDamages == null)
					continue;
				
				if (isWeaponZone && distance % 2 == 1)
					effectDamages = applyBonus(effectDamages, 0.75);
				
				effectDamages = applyReductions(effect, effectDamages, targetInfos.stats);
				
				spellDamages.criticalDamages.push(effectDamages);
			}
			
			return spellDamages;
		}
		
		/**
		 * Test if the target is affected by an effect with targetMask.
		 * 
		 * @param	targetMask
		 * @param	isTargetInMyTeam
		 * @param	isTargetAnInvocation
		 * @param	isTargetMe
		 * @return	Is or not the target affected by the effect.
		 */
		private static function isTargetAffected(targetMask:String, isTargetInMyTeam:Boolean, isTargetAnInvocation:Boolean, isTargetMe:Boolean):Boolean
		{
			var masks:Array = targetMask.split(",");
			
			for each(var mask:String in masks)
			{
				switch(mask)
				{
					case TargetMaskEnum.CASTER:
					case TargetMaskEnum.CASTER_INCLUDED:
						if (isTargetMe)
							return true;
						
						break;
					case TargetMaskEnum.INVOCATION:
					case TargetMaskEnum.STATIC_INVOCATION:
						if (isTargetAnInvocation && isTargetInMyTeam)
							return true;
						
						break;
					case TargetMaskEnum.INVOCATION_ENEMY:
					case TargetMaskEnum.STATIC_INVOCATION_ENEMY:
						if (isTargetAnInvocation && !isTargetInMyTeam)
							return true;
						
						break;
					case TargetMaskEnum.PLAYER:
					case TargetMaskEnum.MONSTER:
						if (!isTargetAnInvocation && isTargetInMyTeam && !isTargetMe)
							return true;
						
						break;
					case TargetMaskEnum.PLAYER_ENEMY:
					case TargetMaskEnum.MONSTER_ENEMY:
						if (!isTargetAnInvocation && !isTargetInMyTeam)
							return true;
						
						break;
					case TargetMaskEnum.ALL:
						if (isTargetInMyTeam)
							return true;
						
						break;
					case TargetMaskEnum.ALL_ENEMY:
						if (!isTargetInMyTeam)
							return true;
						
						break;
					default:
						Api.system.log(2, "Unknow mask : " + mask);
						
						return true;
				}
			}
			
			return false;
		}
		
		/**
		 * Compute the damage of an effect.
		 * 
		 * @param	effect				The effect to compute.
		 * @param	characterStats		Target stats informations.
		 * @param	isCriticalDamage	Is a critical hit ?
		 * @param	criticalBonus		Bonus to initial damages (for weapons).
		 * @param	skillBonus			Bonus of the skill in percent.
		 * @return	The damage that will be deal by that effect.
		 */
		private static function computeInitialDamage(effect:EffectInstance, characterStats:CharacterCharacteristicsInformations, isCriticalDamage:Boolean = false, criticalBonus:int = 0, skillBonus:int = 0):EffectDamages
		{
			var allDamage:int = characterStats.allDamagesBonus.objectsAndMountBonus + characterStats.allDamagesBonus.contextModif;
			var allDamagePercent:int = characterStats.damagesBonusPercent.objectsAndMountBonus + characterStats.damagesBonusPercent.contextModif;
			var criticalDamage:int = (isCriticalDamage) ? characterStats.criticalDamageBonus.objectsAndMountBonus + characterStats.criticalDamageBonus.contextModif : 0;
			
			var effectDamages:EffectDamages = new EffectDamages(effect.effectId);
			
			switch (effect.effectId)
			{
				case EffectIdEnum.ATTACK_WATER_THEFT:
				case EffectIdEnum.ATTACK_WATER:
					var chance:int = characterStats.chance.base + characterStats.chance.objectsAndMountBonus + characterStats.chance.contextModif;
					chance = chance > 0 ? chance : 0;
					
					var waterDamage:int = allDamage + characterStats.waterDamageBonus.objectsAndMountBonus + characterStats.waterDamageBonus.contextModif;
					
					effectDamages.damagesMin =                     Math.floor((effect.parameter0 + criticalBonus) * (1 + ((chance + allDamagePercent + skillBonus) / 100))) + waterDamage + criticalDamage;
					effectDamages.damagesMax = effect.parameter1 ? Math.floor((effect.parameter1 + criticalBonus) * (1 + ((chance + allDamagePercent + skillBonus) / 100))) + waterDamage + criticalDamage : effectDamages.damagesMin;
					
					break;
					
				case EffectIdEnum.ATTACK_EARTH_THEFT:
				case EffectIdEnum.ATTACK_EARTH:
					var strength:int = characterStats.strength.base + characterStats.strength.objectsAndMountBonus + characterStats.strength.contextModif;
					strength = strength > 0 ? strength : 0;
					
					var earthDamage:int = allDamage + characterStats.earthDamageBonus.objectsAndMountBonus + characterStats.earthDamageBonus.contextModif;
					
					effectDamages.damagesMin =                     Math.floor((effect.parameter0 + criticalBonus) * (1 + ((strength + allDamagePercent + skillBonus) / 100))) + earthDamage + criticalDamage;
					effectDamages.damagesMax = effect.parameter1 ? Math.floor((effect.parameter1 + criticalBonus) * (1 + ((strength + allDamagePercent + skillBonus) / 100))) + earthDamage + criticalDamage : effectDamages.damagesMin;
					
					break;
					
				case EffectIdEnum.ATTACK_AIR_THEFT:
				case EffectIdEnum.ATTACK_AIR:
					var agility:int = characterStats.agility.base + characterStats.agility.objectsAndMountBonus + characterStats.agility.contextModif;
					agility = agility > 0 ? agility : 0;
					
					var airDamage:int = allDamage + characterStats.airDamageBonus.objectsAndMountBonus + characterStats.airDamageBonus.contextModif;
					
					effectDamages.damagesMin =                     Math.floor((effect.parameter0 + criticalBonus) * (1 + ((agility + allDamagePercent + skillBonus) / 100))) + airDamage + criticalDamage;
					effectDamages.damagesMax = effect.parameter1 ? Math.floor((effect.parameter1 + criticalBonus) * (1 + ((agility + allDamagePercent + skillBonus) / 100))) + airDamage + criticalDamage : effectDamages.damagesMin;
					
					break;
					
				case EffectIdEnum.ATTACK_FIRE_THEFT:
				case EffectIdEnum.ATTACK_FIRE:
					var intelligence:int = characterStats.intelligence.base + characterStats.intelligence.objectsAndMountBonus + characterStats.intelligence.contextModif;
					agility = agility > 0 ? agility : 0;
					
					var fireDamage:int = allDamage + characterStats.fireDamageBonus.objectsAndMountBonus + characterStats.fireDamageBonus.contextModif;
					
					effectDamages.damagesMin =                     Math.floor((effect.parameter0 + criticalBonus) * (1 + ((intelligence + allDamagePercent + skillBonus) / 100))) + fireDamage + criticalDamage;
					effectDamages.damagesMax = effect.parameter1 ? Math.floor((effect.parameter1 + criticalBonus) * (1 + ((intelligence + allDamagePercent + skillBonus) / 100))) + fireDamage + criticalDamage : effectDamages.damagesMin;
					
					break;
					
				case EffectIdEnum.ATTACK_NEUTRAL_THEFT:
				case EffectIdEnum.ATTACK_NEUTRAL:
					strength = characterStats.strength.base     + characterStats.strength.objectsAndMountBonus     + characterStats.strength.contextModif;
					strength = strength > 0 ? strength : 0;
					
					var neutralDamage:int = allDamage + characterStats.neutralDamageBonus.objectsAndMountBonus + characterStats.neutralDamageBonus.contextModif;
					
					effectDamages.damagesMin =                     Math.floor((effect.parameter0 + criticalBonus) * (1 + ((strength + allDamagePercent + skillBonus) / 100))) + neutralDamage + criticalDamage;
					effectDamages.damagesMax = effect.parameter1 ? Math.floor((effect.parameter1 + criticalBonus) * (1 + ((strength + allDamagePercent + skillBonus) / 100))) + neutralDamage + criticalDamage : effectDamages.damagesMin;
					
					break;
					
				case EffectIdEnum.ATTACK_ERODED_HP_PERCENT:
					
					break;
					
				case EffectIdEnum.ATTACK_PUSHBACK:
					var characterLvl:int = Api.fight.getFighterLevel(Api.fight.getCurrentPlayedFighterId());
					var pushDamage:int = characterStats.pushDamageBonus.base + characterStats.pushDamageBonus.objectsAndMountBonus + characterStats.pushDamageBonus.contextModif;
					
					effectDamages.damagesMin = 0;
					effectDamages.damagesMax = int(effect.parameter0) * (8 + Math.floor(8 * characterLvl / 50)) + pushDamage;
					
					break;
					
				default:
					return null;
			}
			
			return effectDamages;
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
		 * Test if the weapon is a hammer or a staff or a shovel.
		 * 
		 * @param	weaponTypeId	TypeId of the weapon.
		 * @return	True if the weapon is a hammer or a staff or a shovel.
		 */
		public static function isWeaponZone(weaponTypeId:int):Boolean
		{
			if (weaponTypeId == ItemTypeIdEnum.HAMMER || weaponTypeId == ItemTypeIdEnum.STAFF || weaponTypeId == ItemTypeIdEnum.SHOVEL)
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
		private static function applyBonus(damagesRange:EffectDamages, bonusCoeff:Number):EffectDamages
		{
			return damagesRange.mult(bonusCoeff);
		}
		
		/**
		 * Return the power of the skill bonus (if present).
		 * 
		 * @return
		 */
		public static function getSkillBonus():int
		{
			for each(var buff:Object in Api.fight.getAllBuffEffects(Api.fight.getCurrentPlayedFighterId()).buffArray[BuffEffectCategoryEnum.ACTIVE_BONUS])
			{
				if (buff.effects.effectId == EffectIdEnum.SKILL_WEAPON)
				{
					return buff.effects.parameter0;
				}
			}
			
			return 0;
		}
		
		/**
		 * Return if the target is invulnerable.
		 * 
		 * @param	targetId Id of the target.
		 * @return	Is the target invulnerable.
		 */
		public static function isInvulnerable(targetId:int):Boolean
		{
			var invulnerable:Boolean = false;
			
			for each(var buff:Object in Api.fight.getAllBuffEffects(targetId).buffArray[BuffEffectCategoryEnum.STATES])
			{
				if (buff.effects.effectId == EffectIdEnum.STATE_DISABLE && buff.effects.parameter0 == EffectIdEnum.STATE_INVULNERABLE)
				{
					return true;
				}
				
				if (buff.effects.effectId == EffectIdEnum.STATE_APPLY && buff.effects.parameter0 == EffectIdEnum.STATE_INVULNERABLE)
				{
					invulnerable = false;
				}
			}
			
			return invulnerable;
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
		private static function applyReductions(effect:Object, effectDamages:EffectDamages, targetStats:GameFightMinimalStats, isCriticalDamage:Boolean = false):EffectDamages
		{
			switch (effect.effectId) 
			{
				case EffectIdEnum.ATTACK_WATER_THEFT:
				case EffectIdEnum.ATTACK_WATER:
					effectDamages.damagesMin = (1 - targetStats.waterElementResistPercent / 100) * (effectDamages.damagesMin - targetStats.waterElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					effectDamages.damagesMax = (1 - targetStats.waterElementResistPercent / 100) * (effectDamages.damagesMax - targetStats.waterElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case EffectIdEnum.ATTACK_EARTH_THEFT:
				case EffectIdEnum.ATTACK_EARTH:
					effectDamages.damagesMin = (1 - targetStats.earthElementResistPercent / 100) * (effectDamages.damagesMin - targetStats.earthElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					effectDamages.damagesMax = (1 - targetStats.earthElementResistPercent / 100) * (effectDamages.damagesMax - targetStats.earthElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case EffectIdEnum.ATTACK_AIR_THEFT:
				case EffectIdEnum.ATTACK_AIR:
					effectDamages.damagesMin = (1 - targetStats.airElementResistPercent / 100) * (effectDamages.damagesMin - targetStats.airElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					effectDamages.damagesMax = (1 - targetStats.airElementResistPercent / 100) * (effectDamages.damagesMax - targetStats.airElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case EffectIdEnum.ATTACK_FIRE_THEFT:
				case EffectIdEnum.ATTACK_FIRE:
					effectDamages.damagesMin = (1 - targetStats.fireElementResistPercent / 100) * (effectDamages.damagesMin - targetStats.fireElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					effectDamages.damagesMax = (1 - targetStats.fireElementResistPercent / 100) * (effectDamages.damagesMax - targetStats.fireElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case EffectIdEnum.ATTACK_NEUTRAL_THEFT:
				case EffectIdEnum.ATTACK_NEUTRAL:
					effectDamages.damagesMin = (1 - targetStats.neutralElementResistPercent / 100) * (effectDamages.damagesMin - targetStats.neutralElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					effectDamages.damagesMax = (1 - targetStats.neutralElementResistPercent / 100) * (effectDamages.damagesMax - targetStats.neutralElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case EffectIdEnum.ATTACK_PUSHBACK:
					effectDamages.damagesMin -= targetStats.pushDamageFixedResist;
					effectDamages.damagesMax -= targetStats.pushDamageFixedResist;
					
					break;
				default:
			}
			
			if (effectDamages.damagesMax < 0)
			{
				effectDamages.damagesMax = 0;
			}
			
			if (effectDamages.damagesMin < 0)
			{
				effectDamages.damagesMin = 0;
			}
			
			return effectDamages;
		}
		
		/**
		 * Scan all buffs and try to deal with them.
		 * 
		 * @param	damage
		 * @param	target
		 * @return
		 */
		private static function applyBuffReduction(damage:EffectDamages, target:GameFightFighterInformations):EffectDamages
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
		private static function applyElementalArmour(buff:Object, damage:EffectDamages, target:GameFightFighterInformations):EffectDamages
		{
			var level:int = Api.fight.getFighterLevel(target.contextualId);
			
			// Reduction * (100 + 5 * level) / 100
			
			return damage;
		}
	}
}