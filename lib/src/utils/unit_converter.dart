class UnitConverter {
  // --- PRESIÓN ---
  // Base: kPa

  static double toKpa(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'kpa':
        return value;
      case 'pa':
        return value / 1000.0;
      case 'mpa':
        return value * 1000.0;
      case 'bar':
        return value * 100.0;
      default:
        return value;
    }
  }

  static double fromKpa(double kpa, String targetUnit) {
    switch (targetUnit.toLowerCase()) {
      case 'kpa':
        return kpa;
      case 'pa':
        return kpa * 1000.0;
      case 'mpa':
        return kpa / 1000.0;
      case 'bar':
        return kpa / 100.0;
      default:
        return kpa;
    }
  }

  // --- TEMPERATURA ---
  // Base: °C

  static double toCelsius(double value, String unit) {
    switch (unit.toUpperCase()) {
      case 'C':
      case '°C':
        return value;
      case 'K':
        return value - 273.15;
      default:
        return value;
    }
  }

  static double fromCelsius(double celsius, String targetUnit) {
    switch (targetUnit.toUpperCase()) {
      case 'C':
      case '°C':
        return celsius;
      case 'K':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  // --- VOLUMEN ESPECÍFICO ---
  // Base: m³/kg

  static double toM3kg(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'm3/kg':
      case 'm³/kg':
        return value;
      case 'cm3/g':
      case 'cm³/g':
        return value / 1000.0;
      case 'l/kg':
        return value / 1000.0;
      default:
        return value;
    }
  }

  static double fromM3kg(double m3kg, String targetUnit) {
    switch (targetUnit.toLowerCase()) {
      case 'm3/kg':
      case 'm³/kg':
        return m3kg;
      case 'cm3/g':
      case 'cm³/g':
        return m3kg * 1000.0;
      case 'l/kg':
        return m3kg * 1000.0;
      default:
        return m3kg;
    }
  }

  // --- ENERGÍA / ENTALPÍA ---
  // Base: kJ/kg

  static double toKjkg(double value, String unit) {
    switch (unit.toLowerCase()) {
      case 'kj/kg':
        return value;
      case 'j/kg':
        return value / 1000.0;
      case 'cal/g':
        return value * 4.1868;
      default:
        return value;
    }
  }

  static double fromKjkg(double kjkg, String targetUnit) {
    switch (targetUnit.toLowerCase()) {
      case 'kj/kg':
        return kjkg;
      case 'j/kg':
        return kjkg * 1000.0;
      case 'cal/g':
        return kjkg / 4.1868;
      default:
        return kjkg;
    }
  }
}
