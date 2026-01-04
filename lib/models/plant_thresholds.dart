/// Plant water thresholds based on FAO Irrigation and Drainage Paper 56
/// Table 22: Soil water depletion fraction (p) for no stress
///
/// The 'p' value represents the fraction of Total Available Water (TAW)
/// that can be depleted before the plant experiences water stress.
///
/// For M5Stack sensor: We convert p to a "water needed" threshold
/// waterThreshold = (1 - p) * 100  →  sensor % below which plant needs water
library;

enum PlantCategory {
  smallVegetables,
  solanumFamily,
  cucumberFamily,
  rootsAndTubers,
  legumes,
  perennialVegetables,
  cereals,
  tropicalFruits,
  grapesAndBerries,
  fruitTrees,
  houseplants,
}

class PlantThreshold {
  final String name;
  final String nameDE; // German name
  final PlantCategory category;
  final double depletionFraction; // FAO 'p' value (0.0 - 1.0)
  final double minRootDepth; // meters
  final double maxRootDepth; // meters
  final String wateringAdvice;
  final String wateringAdviceDE;

  const PlantThreshold({
    required this.name,
    required this.nameDE,
    required this.category,
    required this.depletionFraction,
    required this.minRootDepth,
    required this.maxRootDepth,
    required this.wateringAdvice,
    required this.wateringAdviceDE,
  });

  /// Convert FAO depletion fraction to sensor threshold
  /// Returns the % below which the plant needs water
  int get waterNeededThreshold => ((1 - depletionFraction) * 100).round();

  /// Returns the optimal moisture range for this plant
  /// Upper bound: avoid waterlogging
  /// Lower bound: before stress occurs
  (int, int) get optimalRange {
    int lower = waterNeededThreshold;
    int upper = (lower + 30).clamp(0, 95); // 30% above stress point, max 95%
    return (lower, upper);
  }

  /// Get status based on current sensor reading
  PlantWaterStatus getStatus(int sensorPercent) {
    if (sensorPercent >= 90) {
      return PlantWaterStatus.tooWet;
    } else if (sensorPercent >= waterNeededThreshold + 20) {
      return PlantWaterStatus.optimal;
    } else if (sensorPercent >= waterNeededThreshold) {
      return PlantWaterStatus.needsWaterSoon;
    } else if (sensorPercent >= waterNeededThreshold - 15) {
      return PlantWaterStatus.needsWaterNow;
    } else {
      return PlantWaterStatus.stressed;
    }
  }
}

enum PlantWaterStatus {
  tooWet,
  optimal,
  needsWaterSoon,
  needsWaterNow,
  stressed,
}

extension PlantWaterStatusExtension on PlantWaterStatus {
  String get label {
    switch (this) {
      case PlantWaterStatus.tooWet:
        return 'Too Wet';
      case PlantWaterStatus.optimal:
        return 'Optimal';
      case PlantWaterStatus.needsWaterSoon:
        return 'Water Soon';
      case PlantWaterStatus.needsWaterNow:
        return 'Water Now!';
      case PlantWaterStatus.stressed:
        return 'Stressed!';
    }
  }

  String get labelDE {
    switch (this) {
      case PlantWaterStatus.tooWet:
        return 'Zu nass';
      case PlantWaterStatus.optimal:
        return 'Optimal';
      case PlantWaterStatus.needsWaterSoon:
        return 'Bald gießen';
      case PlantWaterStatus.needsWaterNow:
        return 'Jetzt gießen!';
      case PlantWaterStatus.stressed:
        return 'Gestresst!';
    }
  }

  String get emoji {
    switch (this) {
      case PlantWaterStatus.tooWet:
        return '';
      case PlantWaterStatus.optimal:
        return '';
      case PlantWaterStatus.needsWaterSoon:
        return '';
      case PlantWaterStatus.needsWaterNow:
        return '';
      case PlantWaterStatus.stressed:
        return '';
    }
  }

  int get colorValue {
    switch (this) {
      case PlantWaterStatus.tooWet:
        return 0xFF2196F3; // Blue
      case PlantWaterStatus.optimal:
        return 0xFF4CAF50; // Green
      case PlantWaterStatus.needsWaterSoon:
        return 0xFFFFEB3B; // Yellow
      case PlantWaterStatus.needsWaterNow:
        return 0xFFFF9800; // Orange
      case PlantWaterStatus.stressed:
        return 0xFFF44336; // Red
    }
  }
}

/// FAO Table 22 - Plant Database
/// Source: https://www.fao.org/4/x0490e/x0490e0e.htm
class PlantDatabase {
  static const List<PlantThreshold> plants = [
    // ============ SMALL VEGETABLES ============
    PlantThreshold(
      name: 'Broccoli',
      nameDE: 'Brokkoli',
      category: PlantCategory.smallVegetables,
      depletionFraction: 0.45,
      minRootDepth: 0.4,
      maxRootDepth: 0.6,
      wateringAdvice: 'Keep soil consistently moist',
      wateringAdviceDE: 'Boden gleichmäßig feucht halten',
    ),
    PlantThreshold(
      name: 'Cabbage',
      nameDE: 'Kohl',
      category: PlantCategory.smallVegetables,
      depletionFraction: 0.45,
      minRootDepth: 0.5,
      maxRootDepth: 0.8,
      wateringAdvice: 'Regular watering, avoid drought',
      wateringAdviceDE: 'Regelmäßig gießen, Trockenheit vermeiden',
    ),
    PlantThreshold(
      name: 'Carrots',
      nameDE: 'Karotten',
      category: PlantCategory.smallVegetables,
      depletionFraction: 0.35,
      minRootDepth: 0.5,
      maxRootDepth: 1.0,
      wateringAdvice: 'Sensitive to drought - water frequently',
      wateringAdviceDE: 'Trockenheitsempfindlich - häufig gießen',
    ),
    PlantThreshold(
      name: 'Celery',
      nameDE: 'Sellerie',
      category: PlantCategory.smallVegetables,
      depletionFraction: 0.20,
      minRootDepth: 0.3,
      maxRootDepth: 0.5,
      wateringAdvice: 'Very sensitive! Keep always moist',
      wateringAdviceDE: 'Sehr empfindlich! Immer feucht halten',
    ),
    PlantThreshold(
      name: 'Garlic',
      nameDE: 'Knoblauch',
      category: PlantCategory.smallVegetables,
      depletionFraction: 0.30,
      minRootDepth: 0.3,
      maxRootDepth: 0.5,
      wateringAdvice: 'Moderate watering, well-drained soil',
      wateringAdviceDE: 'Mäßig gießen, durchlässiger Boden',
    ),
    PlantThreshold(
      name: 'Lettuce',
      nameDE: 'Salat',
      category: PlantCategory.smallVegetables,
      depletionFraction: 0.30,
      minRootDepth: 0.3,
      maxRootDepth: 0.5,
      wateringAdvice: 'Keep moist, shallow roots dry quickly',
      wateringAdviceDE: 'Feucht halten, flache Wurzeln trocknen schnell',
    ),
    PlantThreshold(
      name: 'Onions',
      nameDE: 'Zwiebeln',
      category: PlantCategory.smallVegetables,
      depletionFraction: 0.30,
      minRootDepth: 0.3,
      maxRootDepth: 0.6,
      wateringAdvice: 'Regular watering during growth',
      wateringAdviceDE: 'Regelmäßig gießen während des Wachstums',
    ),
    PlantThreshold(
      name: 'Spinach',
      nameDE: 'Spinat',
      category: PlantCategory.smallVegetables,
      depletionFraction: 0.20,
      minRootDepth: 0.3,
      maxRootDepth: 0.5,
      wateringAdvice: 'Very sensitive to drought!',
      wateringAdviceDE: 'Sehr trockenheitsempfindlich!',
    ),
    PlantThreshold(
      name: 'Radishes',
      nameDE: 'Radieschen',
      category: PlantCategory.smallVegetables,
      depletionFraction: 0.30,
      minRootDepth: 0.3,
      maxRootDepth: 0.5,
      wateringAdvice: 'Keep evenly moist for best flavor',
      wateringAdviceDE: 'Gleichmäßig feucht für besten Geschmack',
    ),

    // ============ SOLANUM FAMILY ============
    PlantThreshold(
      name: 'Tomato',
      nameDE: 'Tomate',
      category: PlantCategory.solanumFamily,
      depletionFraction: 0.40,
      minRootDepth: 0.7,
      maxRootDepth: 1.5,
      wateringAdvice: 'Deep watering, consistent moisture',
      wateringAdviceDE: 'Tief gießen, gleichmäßige Feuchtigkeit',
    ),
    PlantThreshold(
      name: 'Eggplant',
      nameDE: 'Aubergine',
      category: PlantCategory.solanumFamily,
      depletionFraction: 0.45,
      minRootDepth: 0.7,
      maxRootDepth: 1.2,
      wateringAdvice: 'Regular deep watering',
      wateringAdviceDE: 'Regelmäßig tief gießen',
    ),
    PlantThreshold(
      name: 'Bell Pepper',
      nameDE: 'Paprika',
      category: PlantCategory.solanumFamily,
      depletionFraction: 0.30,
      minRootDepth: 0.5,
      maxRootDepth: 1.0,
      wateringAdvice: 'Sensitive - keep consistently moist',
      wateringAdviceDE: 'Empfindlich - gleichmäßig feucht halten',
    ),
    PlantThreshold(
      name: 'Chili Pepper',
      nameDE: 'Chili',
      category: PlantCategory.solanumFamily,
      depletionFraction: 0.30,
      minRootDepth: 0.5,
      maxRootDepth: 1.0,
      wateringAdvice: 'Regular watering, avoid waterlogging',
      wateringAdviceDE: 'Regelmäßig gießen, Staunässe vermeiden',
    ),

    // ============ CUCUMBER FAMILY ============
    PlantThreshold(
      name: 'Cucumber',
      nameDE: 'Gurke',
      category: PlantCategory.cucumberFamily,
      depletionFraction: 0.50,
      minRootDepth: 0.7,
      maxRootDepth: 1.2,
      wateringAdvice: 'Tolerant, but likes consistent moisture',
      wateringAdviceDE: 'Tolerant, mag aber gleichmäßige Feuchtigkeit',
    ),
    PlantThreshold(
      name: 'Pumpkin',
      nameDE: 'Kürbis',
      category: PlantCategory.cucumberFamily,
      depletionFraction: 0.35,
      minRootDepth: 1.0,
      maxRootDepth: 1.5,
      wateringAdvice: 'Deep roots but needs regular water',
      wateringAdviceDE: 'Tiefe Wurzeln, braucht regelmäßig Wasser',
    ),
    PlantThreshold(
      name: 'Zucchini',
      nameDE: 'Zucchini',
      category: PlantCategory.cucumberFamily,
      depletionFraction: 0.50,
      minRootDepth: 0.6,
      maxRootDepth: 1.0,
      wateringAdvice: 'Moderate water needs',
      wateringAdviceDE: 'Mäßiger Wasserbedarf',
    ),
    PlantThreshold(
      name: 'Watermelon',
      nameDE: 'Wassermelone',
      category: PlantCategory.cucumberFamily,
      depletionFraction: 0.40,
      minRootDepth: 0.8,
      maxRootDepth: 1.5,
      wateringAdvice: 'Deep watering, especially during fruiting',
      wateringAdviceDE: 'Tief gießen, besonders während der Fruchtbildung',
    ),

    // ============ ROOTS AND TUBERS ============
    PlantThreshold(
      name: 'Potato',
      nameDE: 'Kartoffel',
      category: PlantCategory.rootsAndTubers,
      depletionFraction: 0.35,
      minRootDepth: 0.4,
      maxRootDepth: 0.6,
      wateringAdvice: 'Consistent moisture for best yield',
      wateringAdviceDE: 'Gleichmäßige Feuchtigkeit für beste Ernte',
    ),
    PlantThreshold(
      name: 'Sweet Potato',
      nameDE: 'Süßkartoffel',
      category: PlantCategory.rootsAndTubers,
      depletionFraction: 0.65,
      minRootDepth: 1.0,
      maxRootDepth: 1.5,
      wateringAdvice: 'Drought tolerant once established',
      wateringAdviceDE: 'Trockenheitstolerant wenn etabliert',
    ),
    PlantThreshold(
      name: 'Beets',
      nameDE: 'Rote Bete',
      category: PlantCategory.rootsAndTubers,
      depletionFraction: 0.50,
      minRootDepth: 0.6,
      maxRootDepth: 1.0,
      wateringAdvice: 'Moderate watering',
      wateringAdviceDE: 'Mäßig gießen',
    ),

    // ============ LEGUMES ============
    PlantThreshold(
      name: 'Green Beans',
      nameDE: 'Grüne Bohnen',
      category: PlantCategory.legumes,
      depletionFraction: 0.45,
      minRootDepth: 0.5,
      maxRootDepth: 0.7,
      wateringAdvice: 'Regular watering during flowering',
      wateringAdviceDE: 'Regelmäßig gießen während der Blüte',
    ),
    PlantThreshold(
      name: 'Peas',
      nameDE: 'Erbsen',
      category: PlantCategory.legumes,
      depletionFraction: 0.35,
      minRootDepth: 0.6,
      maxRootDepth: 1.0,
      wateringAdvice: 'Sensitive during flowering',
      wateringAdviceDE: 'Empfindlich während der Blüte',
    ),
    PlantThreshold(
      name: 'Soybeans',
      nameDE: 'Sojabohnen',
      category: PlantCategory.legumes,
      depletionFraction: 0.50,
      minRootDepth: 0.6,
      maxRootDepth: 1.3,
      wateringAdvice: 'Moderate water needs',
      wateringAdviceDE: 'Mäßiger Wasserbedarf',
    ),

    // ============ PERENNIAL VEGETABLES ============
    PlantThreshold(
      name: 'Strawberries',
      nameDE: 'Erdbeeren',
      category: PlantCategory.perennialVegetables,
      depletionFraction: 0.20,
      minRootDepth: 0.2,
      maxRootDepth: 0.3,
      wateringAdvice: 'Very sensitive! Shallow roots need frequent water',
      wateringAdviceDE:
          'Sehr empfindlich! Flache Wurzeln brauchen häufig Wasser',
    ),
    PlantThreshold(
      name: 'Asparagus',
      nameDE: 'Spargel',
      category: PlantCategory.perennialVegetables,
      depletionFraction: 0.45,
      minRootDepth: 1.2,
      maxRootDepth: 1.8,
      wateringAdvice: 'Deep roots, moderate water needs',
      wateringAdviceDE: 'Tiefe Wurzeln, mäßiger Wasserbedarf',
    ),

    // ============ CEREALS ============
    PlantThreshold(
      name: 'Corn/Maize',
      nameDE: 'Mais',
      category: PlantCategory.cereals,
      depletionFraction: 0.55,
      minRootDepth: 1.0,
      maxRootDepth: 1.7,
      wateringAdvice: 'Critical during tasseling and silking',
      wateringAdviceDE: 'Kritisch während der Blüte',
    ),
    PlantThreshold(
      name: 'Wheat',
      nameDE: 'Weizen',
      category: PlantCategory.cereals,
      depletionFraction: 0.55,
      minRootDepth: 1.0,
      maxRootDepth: 1.5,
      wateringAdvice: 'Moderate tolerance',
      wateringAdviceDE: 'Mäßige Toleranz',
    ),
    PlantThreshold(
      name: 'Rice',
      nameDE: 'Reis',
      category: PlantCategory.cereals,
      depletionFraction: 0.20,
      minRootDepth: 0.5,
      maxRootDepth: 1.0,
      wateringAdvice: 'Needs flooded/very wet conditions',
      wateringAdviceDE: 'Braucht überflutete/sehr nasse Bedingungen',
    ),

    // ============ TROPICAL FRUITS ============
    PlantThreshold(
      name: 'Banana',
      nameDE: 'Banane',
      category: PlantCategory.tropicalFruits,
      depletionFraction: 0.35,
      minRootDepth: 0.5,
      maxRootDepth: 0.9,
      wateringAdvice: 'Loves water! Keep consistently moist',
      wateringAdviceDE: 'Liebt Wasser! Gleichmäßig feucht halten',
    ),
    PlantThreshold(
      name: 'Coffee',
      nameDE: 'Kaffee',
      category: PlantCategory.tropicalFruits,
      depletionFraction: 0.40,
      minRootDepth: 0.9,
      maxRootDepth: 1.5,
      wateringAdvice: 'Regular watering, good drainage',
      wateringAdviceDE: 'Regelmäßig gießen, gute Drainage',
    ),
    PlantThreshold(
      name: 'Pineapple',
      nameDE: 'Ananas',
      category: PlantCategory.tropicalFruits,
      depletionFraction: 0.50,
      minRootDepth: 0.3,
      maxRootDepth: 0.6,
      wateringAdvice: 'Moderate, avoid waterlogging',
      wateringAdviceDE: 'Mäßig, Staunässe vermeiden',
    ),

    // ============ GRAPES AND BERRIES ============
    PlantThreshold(
      name: 'Grapes (Wine)',
      nameDE: 'Weintrauben',
      category: PlantCategory.grapesAndBerries,
      depletionFraction: 0.45,
      minRootDepth: 1.0,
      maxRootDepth: 2.0,
      wateringAdvice: 'Deep roots, moderate stress can improve quality',
      wateringAdviceDE:
          'Tiefe Wurzeln, mäßiger Stress kann Qualität verbessern',
    ),
    PlantThreshold(
      name: 'Berries (Bushes)',
      nameDE: 'Beeren (Büsche)',
      category: PlantCategory.grapesAndBerries,
      depletionFraction: 0.50,
      minRootDepth: 0.6,
      maxRootDepth: 1.2,
      wateringAdvice: 'Regular watering during fruiting',
      wateringAdviceDE: 'Regelmäßig gießen während der Fruchtbildung',
    ),

    // ============ FRUIT TREES ============
    PlantThreshold(
      name: 'Apple',
      nameDE: 'Apfel',
      category: PlantCategory.fruitTrees,
      depletionFraction: 0.50,
      minRootDepth: 1.0,
      maxRootDepth: 2.0,
      wateringAdvice: 'Deep watering, especially when fruiting',
      wateringAdviceDE: 'Tief gießen, besonders bei Fruchtbildung',
    ),
    PlantThreshold(
      name: 'Citrus',
      nameDE: 'Zitrus',
      category: PlantCategory.fruitTrees,
      depletionFraction: 0.50,
      minRootDepth: 1.1,
      maxRootDepth: 1.5,
      wateringAdvice: 'Regular deep watering',
      wateringAdviceDE: 'Regelmäßig tief gießen',
    ),
    PlantThreshold(
      name: 'Avocado',
      nameDE: 'Avocado',
      category: PlantCategory.fruitTrees,
      depletionFraction: 0.70,
      minRootDepth: 0.5,
      maxRootDepth: 1.0,
      wateringAdvice: 'Drought tolerant, avoid overwatering!',
      wateringAdviceDE: 'Trockenheitstolerant, nicht übergießen!',
    ),
    PlantThreshold(
      name: 'Olive',
      nameDE: 'Olive',
      category: PlantCategory.fruitTrees,
      depletionFraction: 0.65,
      minRootDepth: 1.2,
      maxRootDepth: 1.7,
      wateringAdvice: 'Very drought tolerant',
      wateringAdviceDE: 'Sehr trockenheitstolerant',
    ),

    // ============ COMMON HOUSEPLANTS (estimated based on similar plants) ============
    PlantThreshold(
      name: 'Basil',
      nameDE: 'Basilikum',
      category: PlantCategory.houseplants,
      depletionFraction: 0.30,
      minRootDepth: 0.2,
      maxRootDepth: 0.4,
      wateringAdvice: 'Keep moist but not waterlogged',
      wateringAdviceDE: 'Feucht halten, aber keine Staunässe',
    ),
    PlantThreshold(
      name: 'Mint',
      nameDE: 'Minze',
      category: PlantCategory.houseplants,
      depletionFraction: 0.40,
      minRootDepth: 0.4,
      maxRootDepth: 0.8,
      wateringAdvice: 'Likes moisture, hard to overwater',
      wateringAdviceDE: 'Mag Feuchtigkeit, schwer zu übergießen',
    ),
    PlantThreshold(
      name: 'Rosemary',
      nameDE: 'Rosmarin',
      category: PlantCategory.houseplants,
      depletionFraction: 0.60,
      minRootDepth: 0.3,
      maxRootDepth: 0.6,
      wateringAdvice: 'Drought tolerant, let dry between watering',
      wateringAdviceDE: 'Trockenheitstolerant, zwischen Gießen trocknen lassen',
    ),
    PlantThreshold(
      name: 'Lavender',
      nameDE: 'Lavendel',
      category: PlantCategory.houseplants,
      depletionFraction: 0.65,
      minRootDepth: 0.3,
      maxRootDepth: 0.5,
      wateringAdvice: 'Very drought tolerant, avoid overwatering',
      wateringAdviceDE: 'Sehr trockenheitstolerant, nicht übergießen',
    ),
    PlantThreshold(
      name: 'Ficus',
      nameDE: 'Ficus',
      category: PlantCategory.houseplants,
      depletionFraction: 0.50,
      minRootDepth: 0.3,
      maxRootDepth: 0.8,
      wateringAdvice: 'Let top soil dry between watering',
      wateringAdviceDE: 'Obere Erde zwischen Gießen trocknen lassen',
    ),
    PlantThreshold(
      name: 'Peace Lily',
      nameDE: 'Einblatt',
      category: PlantCategory.houseplants,
      depletionFraction: 0.35,
      minRootDepth: 0.2,
      maxRootDepth: 0.4,
      wateringAdvice: 'Likes moisture, will droop when thirsty',
      wateringAdviceDE: 'Mag Feuchtigkeit, hängt wenn durstig',
    ),
    PlantThreshold(
      name: 'Snake Plant',
      nameDE: 'Bogenhanf',
      category: PlantCategory.houseplants,
      depletionFraction: 0.75,
      minRootDepth: 0.2,
      maxRootDepth: 0.4,
      wateringAdvice: 'Very drought tolerant! Let dry completely',
      wateringAdviceDE: 'Sehr trockenheitstolerant! Komplett trocknen lassen',
    ),
    PlantThreshold(
      name: 'Pothos',
      nameDE: 'Efeutute',
      category: PlantCategory.houseplants,
      depletionFraction: 0.50,
      minRootDepth: 0.2,
      maxRootDepth: 0.4,
      wateringAdvice: 'Let top inch dry between watering',
      wateringAdviceDE: 'Obere Schicht zwischen Gießen trocknen lassen',
    ),
    PlantThreshold(
      name: 'Monstera',
      nameDE: 'Monstera',
      category: PlantCategory.houseplants,
      depletionFraction: 0.45,
      minRootDepth: 0.3,
      maxRootDepth: 0.6,
      wateringAdvice: 'Moderate watering, good drainage',
      wateringAdviceDE: 'Mäßig gießen, gute Drainage',
    ),
    PlantThreshold(
      name: 'Succulent/Cactus',
      nameDE: 'Sukkulente/Kaktus',
      category: PlantCategory.houseplants,
      depletionFraction: 0.80,
      minRootDepth: 0.1,
      maxRootDepth: 0.3,
      wateringAdvice: 'Minimal water! Let dry completely',
      wateringAdviceDE: 'Minimal gießen! Komplett trocknen lassen',
    ),

    // Default/Generic plant
    PlantThreshold(
      name: 'Generic Plant',
      nameDE: 'Allgemeine Pflanze',
      category: PlantCategory.houseplants,
      depletionFraction: 0.50,
      minRootDepth: 0.3,
      maxRootDepth: 0.6,
      wateringAdvice: 'Water when top soil feels dry',
      wateringAdviceDE: 'Gießen wenn obere Erde sich trocken anfühlt',
    ),
  ];

  /// Get all plants sorted alphabetically
  static List<PlantThreshold> get sortedByName {
    final sorted = List<PlantThreshold>.from(plants);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Get plants by category
  static List<PlantThreshold> getByCategory(PlantCategory category) {
    return plants.where((p) => p.category == category).toList();
  }

  /// Search plants by name
  static List<PlantThreshold> search(String query) {
    final lowerQuery = query.toLowerCase();
    return plants
        .where(
          (p) =>
              p.name.toLowerCase().contains(lowerQuery) ||
              p.nameDE.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  /// Get default plant (Generic)
  static PlantThreshold get defaultPlant =>
      plants.firstWhere((p) => p.name == 'Generic Plant');
}
