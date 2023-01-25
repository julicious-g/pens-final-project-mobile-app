import 'package:final_project/models/attributes.dart';
import 'package:final_project/services/sensor/sensor_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../models/plant.dart';

class PlantRecommendationService {
  Map<String, Plant> _plantMap = <String, Plant>{};
  final Map<String, Function> _sensorCheckFunctions = <String, Function>{};

  late SensorService _sensorService;

  PlantRecommendationService() {
    _sensorService = GetIt.instance<SensorService>();

    _sensorCheckFunctions["ph"] = _ispHMatch;
    _sensorCheckFunctions["salinity"] = _isSalinityMatch;
    _sensorCheckFunctions["temperature"] = _isSalinityMatch;
  }

  List<String> plantIds() => _plantMap.entries.map((e) => e.key).toList();
  Plant plant(String key) => _plantMap[key]!;
  Listenable listenable() => _sensorService;

  List<String> plantIdsOrderedByProperties() {
    var plantList = plantIds();

    // plantList.sort((b, a) => matchedCount(a).compareTo(matchedCount(b)));
    return plantList;
  }

  Future<PlantRecommendationService> init() async {
    var plants = await Plant.fromFile();
    _plantMap = {for (var p in plants) p.id: p};
    return this;
  }

  int matchedCount(String plantId) {
    var plant = this.plant(plantId);
    var matchCount = 0;
    _sensorCheckFunctions.forEach((key, value) =>
        matchCount = value(plant) ? matchCount + 1 : matchCount);

    return matchCount;
  }

  String atrributeLevel(String attributeType, Plant plant) {
    Map<String, dynamic> attribute = plant.attributes[attributeType];
    String result = "N";

    attribute.forEach((key, value) {
      var sensorValue = _sensorService.getSensorValue(attributeType) ?? 0.0;

      if (sensorValue >= value["min"] && sensorValue <= value["max"]) {
        result = key.toUpperCase();
      }
    });

    return result;
  }

  bool isMatchAll(Plant plant) {
    var ret = true;

    _sensorCheckFunctions.forEach((key, value) => ret = ret && value(plant));

    return ret;
  }

  bool isMatch(String sensor, Plant plant) {
    var func = _sensorCheckFunctions[sensor] ?? (Plant plant) => false;
    return func(plant);
  }

  bool _ispHMatch(Plant plant) {
    var sensorPh = _sensorService.getSensorValue(PlantAttribute.ph) ?? 0;

    return sensorPh <= plant.maxPh && sensorPh >= plant.minPh;
  }

  bool _isTemperatureMatch(Plant plant) {
    return false;
  }

  bool _isMoistureMatch(Plant plant) {
    return false;
  }

  bool _isSalinityMatch(Plant plant) {
    var sensorSalinity = 0;

    return sensorSalinity <= plant.salinity;
  }
}
