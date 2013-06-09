package utils 
{
	import d2data.EffectInstance;
	import d2data.EffectsListWrapper;
	import d2data.SpellWrapper;
	import d2data.WeaponWrapper;
	import d2network.CharacterCharacteristicsInformations;
	import d2network.GameFightFighterInformations;
	import d2network.GameFightMinimalStats;
	import enum.BuffEffectCategoryEnum;
	import enum.EffectIdEnum;
	import enum.ItemTypeIdEnum;
	import enum.TargetMaskEnum;
	import types.Damages;
	import types.Range;
	
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
		public static function computeDamages(spell:Object, targetInfos:GameFightFighterInformations, distance:int):Damages
		{
			if (isInvulnerable(targetInfos.contextualId))
			{
				return new Damages(new Range(), new Range(), 0, true);
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
		private static function computeDamagesSpell(spell:SpellWrapper, targetInfos:GameFightFighterInformations, distance:int):Damages
		{
			var characterStats:CharacterCharacteristicsInformations = Api.fight.getCurrentPlayedCharacteristicsInformations();
			
			var targeterTeam:String = Api.fight.getFighterInformations(targetInfos.contextualId).team;
			var targetTeam:String = Api.fight.getFighterInformations(Api.fight.getCurrentPlayedFighterId()).team;
			
			var isTargetMe:Boolean = (targetInfos.contextualId == Api.fight.getCurrentPlayedFighterId());
			var isTargetInMyTeam:Boolean = (targeterTeam == targetTeam);
			var isTargetAnInvocation:Boolean = targetInfos.stats.summoned;
			
			var effect:EffectInstance = null;
			
			var damageEffect:Range = null;
			var damageNormal:Range = new Range();
			var damageCritical:Range = new Range();
			
			var doDamage:Boolean = false;
			
			// Simple damages
			for (var ii:int = 0; ii < spell.effects.length; ii++)
			{
				effect = spell.effects[ii];
				
				if (!isTargetAffected(effect.targetMask, isTargetInMyTeam, isTargetAnInvocation, isTargetMe))
					continue;
				
				damageEffect = computeInitialDamage(effect, characterStats);
				if (damageEffect == null)
					continue;
				
				if (distance != 0 && isSpellZone(spell.spellZoneEffects, ii))
					damageEffect = applyBonus(damageEffect, 1.0 - 0.1 * distance);
				
				damageEffect = applyReductions(effect, damageEffect, targetInfos.stats);
				
				damageNormal.min += damageEffect.min;
				damageNormal.max += damageEffect.max;
				
				doDamage = true;
			}
			
			// Critical damages
			for (ii = 0; ii < spell.criticalEffect.length; ii++)
			{
				effect = spell.criticalEffect[ii];
				
				if (!isTargetAffected(effect.targetMask, isTargetInMyTeam, isTargetAnInvocation, isTargetMe))
					continue;
				
				damageEffect = computeInitialDamage(effect, characterStats, true);
				if (damageEffect == null)
					continue;
				
				if (distance != 0 && isSpellZone(spell.spellZoneEffects, ii))
					damageEffect = applyBonus(damageEffect, 1.0 - 0.1 * distance);
				
				damageEffect = applyReductions(effect, damageEffect, targetInfos.stats, true);
				
				damageCritical.min += damageEffect.min;
				damageCritical.max += damageEffect.max;
				
				doDamage = true;
			}
			
			if (doDamage == false)
				return null;
			
			return new Damages(damageNormal, damageCritical, distance);
		}
		
		/**
		 * Compute initial damages (for weapons).
		 * 
		 * @param	weapon		Weapon informations.
		 * @param	targetInfos	Target informations (characteristics, ...).
		 * @param	distance	Distance between the targeted point and the target.
		 * @return	A Damage object and Null if error.
		 */
		private static function computeDamagesWeapon(weapon:WeaponWrapper, targetInfos:GameFightFighterInformations, distance:int):Damages
		{
			var isWeaponZone:Boolean = isWeaponZone(weapon.typeId);
			var characterStats:CharacterCharacteristicsInformations = Api.fight.getCurrentPlayedCharacteristicsInformations();
			var skillBonus:int = getSkillBonus();
			
			var effect:EffectInstance;
			
			var damageEffect:Range;
			var damageNormal:Range = new Range();
			var damageCritical:Range = new Range();
			
			// Simple damages
			for each (effect in weapon.effects)
			{
				damageEffect = computeInitialDamage(effect, characterStats, false, 0, skillBonus);
				if (damageEffect == null)
					continue;
				
				if (isWeaponZone && distance % 2 == 1)
					damageEffect = applyBonus(damageEffect, 0.75);
				
				damageEffect = applyReductions(effect, damageEffect, targetInfos.stats);
				
				damageNormal.min += damageEffect.min;
				damageNormal.max += damageEffect.max;
			}
			
			// Critical damages
			for each (effect in weapon.effects)
			{
				damageEffect = computeInitialDamage(effect, characterStats, true, weapon.criticalHitBonus, skillBonus);
				if (damageEffect == null)
					continue;
				
				if (isWeaponZone && distance % 2 == 1)
					damageEffect = applyBonus(damageEffect, 0.75);
				
				damageEffect = applyReductions(effect, damageEffect, targetInfos.stats);
				
				damageCritical.min += damageEffect.min;
				damageCritical.max += damageEffect.max;
			}
			
			return new Damages(damageNormal, damageCritical, isWeaponZone ? distance : 0);
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
		private static function computeInitialDamage(effect:EffectInstance, characterStats:CharacterCharacteristicsInformations, isCriticalDamage:Boolean = false, criticalBonus:int = 0, skillBonus:int = 0):Range
		{
			var allDamage:int = characterStats.allDamagesBonus.objectsAndMountBonus + characterStats.allDamagesBonus.contextModif;
			var allDamagePercent:int = characterStats.damagesBonusPercent.objectsAndMountBonus + characterStats.damagesBonusPercent.contextModif;
			var criticalDamage:int = (isCriticalDamage) ? characterStats.criticalDamageBonus.objectsAndMountBonus + characterStats.criticalDamageBonus.contextModif : 0;
			
			var damage:Range = new Range();
			
			switch (effect.effectId)
			{
				case EffectIdEnum.WATER_THEFT:
				case EffectIdEnum.WATER:
					var chance:int = characterStats.chance.base + characterStats.chance.objectsAndMountBonus + characterStats.chance.contextModif;
					chance = chance > 0 ? chance : 0;
					
					var waterDamage:int = allDamage + characterStats.waterDamageBonus.objectsAndMountBonus + characterStats.waterDamageBonus.contextModif;
					
					damage.min =                     Math.floor((effect.parameter0 + criticalBonus) * (1 + ((chance + allDamagePercent + skillBonus) / 100))) + waterDamage + criticalDamage;
					damage.max = effect.parameter1 ? Math.floor((effect.parameter1 + criticalBonus) * (1 + ((chance + allDamagePercent + skillBonus) / 100))) + waterDamage + criticalDamage : damage.min;
					
					break;
					
				case EffectIdEnum.EARTH_THEFT:
				case EffectIdEnum.EARTH:
					var strength:int = characterStats.strength.base + characterStats.strength.objectsAndMountBonus + characterStats.strength.contextModif;
					strength = strength > 0 ? strength : 0;
					
					var earthDamage:int = allDamage + characterStats.earthDamageBonus.objectsAndMountBonus + characterStats.earthDamageBonus.contextModif;
					
					damage.min =                     Math.floor((effect.parameter0 + criticalBonus) * (1 + ((strength + allDamagePercent + skillBonus) / 100))) + earthDamage + criticalDamage;
					damage.max = effect.parameter1 ? Math.floor((effect.parameter1 + criticalBonus) * (1 + ((strength + allDamagePercent + skillBonus) / 100))) + earthDamage + criticalDamage : damage.min;
					
					break;
					
				case EffectIdEnum.AIR_THEFT:
				case EffectIdEnum.AIR:
					var agility:int = characterStats.agility.base + characterStats.agility.objectsAndMountBonus + characterStats.agility.contextModif;
					agility = agility > 0 ? agility : 0;
					
					var airDamage:int = allDamage + characterStats.airDamageBonus.objectsAndMountBonus + characterStats.airDamageBonus.contextModif;
					
					damage.min =                     Math.floor((effect.parameter0 + criticalBonus) * (1 + ((agility + allDamagePercent + skillBonus) / 100))) + airDamage + criticalDamage;
					damage.max = effect.parameter1 ? Math.floor((effect.parameter1 + criticalBonus) * (1 + ((agility + allDamagePercent + skillBonus) / 100))) + airDamage + criticalDamage : damage.min;
					
					break;
					
				case EffectIdEnum.FIRE_THEFT:
				case EffectIdEnum.FIRE:
					var intelligence:int = characterStats.intelligence.base + characterStats.intelligence.objectsAndMountBonus + characterStats.intelligence.contextModif;
					agility = agility > 0 ? agility : 0;
					
					var fireDamage:int = allDamage + characterStats.fireDamageBonus.objectsAndMountBonus + characterStats.fireDamageBonus.contextModif;
					
					damage.min =                     Math.floor((effect.parameter0 + criticalBonus) * (1 + ((intelligence + allDamagePercent + skillBonus) / 100))) + fireDamage + criticalDamage;
					damage.max = effect.parameter1 ? Math.floor((effect.parameter1 + criticalBonus) * (1 + ((intelligence + allDamagePercent + skillBonus) / 100))) + fireDamage + criticalDamage : damage.min;
					
					break;
					
				case EffectIdEnum.NEUTRAL_THEFT:
				case EffectIdEnum.NEUTRAL:
					strength = characterStats.strength.base     + characterStats.strength.objectsAndMountBonus     + characterStats.strength.contextModif;
					strength = strength > 0 ? strength : 0;
					
					var neutralDamage:int = allDamage + characterStats.neutralDamageBonus.objectsAndMountBonus + characterStats.neutralDamageBonus.contextModif;
					
					damage.min =                     Math.floor((effect.parameter0 + criticalBonus) * (1 + ((strength + allDamagePercent + skillBonus) / 100))) + neutralDamage + criticalDamage;
					damage.max = effect.parameter1 ? Math.floor((effect.parameter1 + criticalBonus) * (1 + ((strength + allDamagePercent + skillBonus) / 100))) + neutralDamage + criticalDamage : damage.min;
					
					break;
					
				case EffectIdEnum.ERODED_HP_PERCENT:
					
					break;
					
				case EffectIdEnum.PUSHBACK:
					var characterLvl:int = Api.fight.getFighterLevel(Api.fight.getCurrentPlayedFighterId());
					var pushDamage:int = characterStats.pushDamageBonus.base + characterStats.pushDamageBonus.objectsAndMountBonus + characterStats.pushDamageBonus.contextModif;
					
					damage.min = 0;
					damage.max = int(effect.parameter0) * (8 + Math.floor(8 * characterLvl / 50)) + pushDamage;
					
					break;
					
				default:
					return null;
			}
			
			return damage;
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
		private static function isWeaponZone(weaponTypeId:int):Boolean
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
		private static function applyBonus(damagesRange:Range, bonusCoeff:Number):Range
		{
			return damagesRange.mult(bonusCoeff);
		}
		
		/**
		 * Return the power of the skill bonus (if present).
		 * 
		 * @return
		 */
		private static function getSkillBonus():int
		{
			for each(var buff:Object in Api.fight.getAllBuffEffects(Api.fight.getCurrentPlayedFighterId()).buffArray[BuffEffectCategoryEnum.ACTIVE_BONUS])
			{
				if (buff.effects.effectId == EffectIdEnum.POWER_WEAPON)
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
		private static function isInvulnerable(targetId:int):Boolean
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
		private static function applyReductions(effect:Object, damage:Range, targetStats:GameFightMinimalStats, isCriticalDamage:Boolean = false):Range
		{
			switch (effect.effectId) 
			{
				case EffectIdEnum.WATER_THEFT:
				case EffectIdEnum.WATER:
					damage.min = (1 - targetStats.waterElementResistPercent / 100) * (damage.min - targetStats.waterElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					damage.max = (1 - targetStats.waterElementResistPercent / 100) * (damage.max - targetStats.waterElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case EffectIdEnum.EARTH_THEFT:
				case EffectIdEnum.EARTH:
					damage.min = (1 - targetStats.earthElementResistPercent / 100) * (damage.min - targetStats.earthElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					damage.max = (1 - targetStats.earthElementResistPercent / 100) * (damage.max - targetStats.earthElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case EffectIdEnum.AIR_THEFT:
				case EffectIdEnum.AIR:
					damage.min = (1 - targetStats.airElementResistPercent / 100) * (damage.min - targetStats.airElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					damage.max = (1 - targetStats.airElementResistPercent / 100) * (damage.max - targetStats.airElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case EffectIdEnum.FIRE_THEFT:
				case EffectIdEnum.FIRE:
					damage.min = (1 - targetStats.fireElementResistPercent / 100) * (damage.min - targetStats.fireElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					damage.max = (1 - targetStats.fireElementResistPercent / 100) * (damage.max - targetStats.fireElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case EffectIdEnum.NEUTRAL_THEFT:
				case EffectIdEnum.NEUTRAL:
					damage.min = (1 - targetStats.neutralElementResistPercent / 100) * (damage.min - targetStats.neutralElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					damage.max = (1 - targetStats.neutralElementResistPercent / 100) * (damage.max - targetStats.neutralElementReduction - (isCriticalDamage ? targetStats.criticalDamageFixedResist : 0));
					
					break;
				case EffectIdEnum.PUSHBACK:
					damage.min -= targetStats.pushDamageFixedResist;
					damage.max -= targetStats.pushDamageFixedResist;
					
					break;
				default:
			}
			
			if (damage.max < 0)
			{
				damage.max = 0;
			}
			
			if (damage.min < 0)
			{
				damage.min = 0;
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