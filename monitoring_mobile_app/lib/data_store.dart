class DataStore {
  // Singleton instance
  static DataStore? _instance;

  factory DataStore() {
    _instance ??= DataStore._internal();
    return _instance!;
  }

  DataStore._internal();

  // Storage untuk health komponen
  final Map<String, Map<String, int>> componentHealth = {};

  // ✅ BARU: Storage untuk bobot komponen (berdasarkan spreadsheet: total bobot = 100)
  final Map<String, Map<String, double>> komponenWeights = {};

  // Storage untuk data lori (HM, inspector, dll)
  final Map<String, Map<String, dynamic>> loriData = {};

  // Storage untuk data detail komponen (parameter, catatan, dll)
  final Map<String, Map<String, dynamic>> componentData = {};

  // ✅ BARU: Storage untuk daftar lori (list semua lori)
  List<Map<String, dynamic>>? loriList;

  // Get health komponen
  int getComponentHealth(String loriName, String componentName) {
    return componentHealth[loriName]?[componentName] ?? 0;
  }

  // Set health komponen
  void setComponentHealth(String loriName, String componentName, int health) {
    if (componentHealth[loriName] == null) {
      componentHealth[loriName] = {};
    }
    componentHealth[loriName]![componentName] = health;
  }

  // ✅ Get bobot komponen
  double getKomponenWeight(String loriName, String componentName) {
    return komponenWeights[loriName]?[componentName] ?? 0.0;
  }

  // ✅ Set bobot komponen
  void setKomponenWeight(String loriName, String componentName, double weight) {
    if (komponenWeights[loriName] == null) {
      komponenWeights[loriName] = {};
    }
    komponenWeights[loriName]![componentName] = weight;
  }

  // Hitung overall health lori berbobot
  // Rumus: sum(health_i * weight_i) / sum(weight_i)
  double getLoriOverallHealth(String loriName) {
    Map<String, int>? components = componentHealth[loriName];
    if (components == null || components.isEmpty) return 0;

    double weightedSum = 0;
    double totalWeight = 0;

    for (final entry in components.entries) {
      final componentName = entry.key;
      final health = entry.value;
      final weight = getKomponenWeight(loriName, componentName);
      weightedSum += health * weight;
      totalWeight += weight;
    }

    if (totalWeight == 0) return 0;
    return weightedSum / totalWeight;
  }

  // Simpan data lori
  void setLoriData(String loriName, Map<String, dynamic> data) {
    loriData[loriName] = Map<String, dynamic>.from(data);
  }

  // Ambil data lori
  Map<String, dynamic>? getLoriData(String loriName) {
    return loriData[loriName];
  }

  // Simpan data komponen (parameter detail, catatan, dll)
  void setComponentData(String componentKey, Map<String, dynamic> data) {
    componentData[componentKey] = data;
  }

  // Ambil data komponen
  Map<String, dynamic>? getComponentData(String componentKey) {
    return componentData[componentKey];
  }

  // ✅ BARU: Simpan daftar lori
  void setLoriList(List<Map<String, dynamic>> list) {
    loriList = List<Map<String, dynamic>>.from(list);
    print('[DataStore] Lori list saved: ${loriList!.length} items');
  }

  // ✅ BARU: Ambil daftar lori
  List<Map<String, dynamic>>? getLoriList() {
    return loriList;
  }
}
