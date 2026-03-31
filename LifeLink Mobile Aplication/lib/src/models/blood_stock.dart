enum StatusLevel { normal, low, critical }

class BloodStock {
  final String type;
  final int units;
  final String label;
  final StatusLevel level;

  BloodStock(this.type, this.units, this.label, this.level);
}